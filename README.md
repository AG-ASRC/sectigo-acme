# Sectigo ACME

Automatisation de l'émission et du renouvellement de certificats Sectigo avec un challenge DNS-01. Le dépôt contient deux parcours indépendants : Windows avec win-acme (WACS) et IIS, et Linux avec Certbot et cron. Sous Linux, cron redémarre le serveur Web après chaque exécution réussie du contrôle quotidien.

## Architecture

Les deux plateformes utilisent le même principe : le client ACME demande un challenge DNS-01, un hook délègue la création du TXT à un Cloudflare Worker, puis le certificat est installé sur l'hôte.

```mermaid
flowchart LR
    Sectigo["Autorité ACME Sectigo"]
    Worker["Cloudflare Worker<br/>POST /dns · DELETE /dns"]
    DNS["Zone DNS Cloudflare"]

    subgraph Windows["Windows"]
        WinScheduler["Tâche planifiée<br/>quotidienne, SYSTEM"] --> WinTask["task.ps1<br/>contrôle du certificat"]
        WinTask --> WinDecision{"Absent ou expire<br/>avant MaxDays ?"}
        WinDecision -->|Oui| WacsScript["certbot.ps1"] --> WACS["win-acme (WACS)"]
        WinDecision -->|Non| WinLog["Journal Application"]
        WACS --> WinHook["acme-hook.ps1"]
        WACS --> WinStore["Magasin ordinateur<br/>LocalMachine / My (configurable)"]
        WinHook <-->|Défi DNS-01| Worker
        WACS <-->|ACME| Sectigo
        WinStore --> IIS["iis.ps1<br/>liaisons HTTPS"]
    end

    subgraph Linux["Linux"]
        Cron["cron<br/>tous les jours à 03:00"] --> CronScript["crontab.sh"]
        CronScript --> LinuxCertCheck{"Certificat présent ?"}
        LinuxCertCheck -->|Non : openssl échoue| LinuxError["Échec avant Certbot"]
        LinuxCertCheck -->|Oui| LinuxCheck{"Expire dans MaxDays ?"}
        LinuxCheck -->|Non| LinuxLog["Journalisation de validité"]
        LinuxCheck -->|Oui| CertbotScript["certbot.sh"] --> Certbot["Certbot"]
        Certbot --> LinuxHook["acme-hook.sh"]
        LinuxHook <-->|Défi DNS-01| Worker
        Certbot <-->|ACME| Sectigo
        Certbot --> CertFiles["Certificats sous CertificatsPath"]
        CronScript -->|après chaque exécution réussie| CronRestart["Redémarrage du serveur Web"]
    end

    Worker --> DNS
```

Le code du Cloudflare Worker n'est pas inclus dans ce dépôt. Le Worker doit accepter les requêtes `POST /dns` et `DELETE /dns` authentifiées par l'en-tête `X-API-Token`.

## Documentation par plateforme

- [Guide Windows](docs/windows.md) — configuration WACS, magasin Windows, IIS et tâche planifiée.
- [Guide Linux](docs/linux.md) — Certbot, hooks DNS, configuration, secrets et cron.

## Secrets et configuration

Les fichiers de configuration et de secrets propres à chaque hôte sont locaux et ignorés par Git. Utilisez les fichiers `.example` comme modèles, renseignez les secrets sur la machine cible et limitez leurs permissions. Ne publiez jamais les identifiants Sectigo EAB ni le jeton du Worker.

## Historique

Voir le [changelog](CHANGELOGS.md).
