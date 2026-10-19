# Guide Linux

La configuration Linux s'appuie sur Certbot en mode manuel DNS-01, des hooks shell, un Cloudflare Worker et cron. Les scripts sont encore en cours de mise au point ; lisez la section [Limitations connues](#limitations-connues) avant de les utiliser en production.

## Architecture et déroulement prévu

1. `make-crontab.sh` installe un job cron à 03:00 qui lance `crontab.sh`.
2. `crontab.sh` lit la date d'expiration du certificat sous `${CertificatsPath}/live/${DomainOnly}/fullchain.pem` et compare cette date au seuil `MaxDays`.
3. Si le certificat expire dans le seuil configuré, `crontab.sh` journalise le renouvellement puis lance le script indiqué par `CerbotPath`. Sinon, il journalise la date de validité et n'appelle pas Certbot.
4. `certbot.sh` demande un certificat à Sectigo via Certbot et configure `acme-hook.sh` comme hook d'authentification et de nettoyage.
5. `acme-hook.sh` crée ou supprime `_acme-challenge.<domaine>` avec le Cloudflare Worker et attend `CoolDownBeforeCheckChallenge` après la création.
6. Après succès, `certbot.sh` écrit un message dans le journal configuré. La commande cron redémarre ensuite le service défini par `WebServer` si `crontab.sh` s'est terminé sans erreur, qu'un renouvellement ait eu lieu ou non.

Les requêtes du hook utilisent `POST /dns` pour créer le TXT et `DELETE /dns` pour le supprimer, avec l'en-tête `X-API-Token`.
Les scripts chargent `config.env`, `secrets.env` et `translation.env` avec des chemins relatifs au répertoire courant. Ils doivent donc être lancés depuis le répertoire contenant les fichiers de configuration. Le hook ne crée pas actuellement de fichier temporaire pour la valeur de validation.

## Configuration

Copiez `linux/config.env.example` vers `linux/config.env`, puis copiez `linux/secrets.env.example` vers `linux/secrets.env`. Remplacez la valeur d'exemple de `Domain` par un seul domaine valide (par exemple `Domain=*.example.com` ou `Domain=example.com`) ; ne conservez pas le séparateur `|` du modèle. Le fichier `linux/translation.env` fournit les messages utilisés par les scripts.

| Clé de configuration | Utilisation |
| --- | --- |
| `ServerUrl` | Endpoint Sectigo ACME transmis à Certbot. |
| `Domain` | Domaine demandé à Certbot ; sélectionnez une seule valeur, par exemple `*.example.com` ou `example.com`. |
| `DomainOnly` | Nom d'hôte utilisé pour rechercher le fichier `fullchain.pem` sous `${CertificatsPath}/live/`. |
| `AcmeScriptPath` | Chemin du hook DNS Certbot. |
| `CertificatsPath` | Répertoire de configuration et de certificats Certbot. |
| `WorkerUrl` | URL du Cloudflare Worker. |
| `MaxDays` | Seuil de renouvellement prévu en jours. |
| `CoolDownBeforeCheckChallenge` | Attente en secondes après la création du TXT. |
| `WebServer` | Unité systemd redémarrée par cron après chaque exécution réussie, par exemple `apache2` ou `nginx`. |
| `CerbotPath` | Chemin du script Certbot appelé par `crontab.sh`. La clé conserve cette orthographe dans le fichier d'exemple et le script. |
| `CrontabPath` | Chemin du script périodique `crontab.sh` utilisé par cron. |
| `LogsPath` | Chemin de journalisation utilisé par les scripts. |

Dans `linux/secrets.env`, définissez `EabKid`, `EabHmac` et `ApiToken`. Ne placez pas de valeurs réelles dans les fichiers `.example`. Limitez l'accès aux secrets, par exemple avec `chmod 600 linux/secrets.env`, et vérifiez que le compte qui exécute cron peut les lire.

## Scripts

| Script | Rôle |
| --- | --- |
| `linux/make-crontab.sh` | Ajoute le job quotidien à crontab s'il n'est pas déjà présent. |
| `linux/crontab.sh` | Cherche le certificat et orchestre le renouvellement planifié. |
| `linux/certbot.sh` | Demande le certificat à Sectigo et journalise le résultat. |
| `linux/acme-hook.sh` | Crée ou supprime le challenge DNS-01 via le Worker et conserve temporairement la valeur du challenge à côté du script. |

## Limitations connues

- `crontab.sh` appelle `openssl` sur le fichier du certificat avant de vérifier que ce fichier existe. Une première émission ne peut donc pas être déclenchée proprement par cron tant que le certificat est absent ; prévoyez l'émission initiale séparément ou gérez explicitement l'absence du fichier.
- Vérifiez que `DomainOnly` correspond à l'arborescence réellement créée par Certbot pour le certificat demandé.
- La commande cron redémarre le service Web après chaque retour réussi de `crontab.sh`, même lorsqu'aucun renouvellement n'a eu lieu. `certbot.sh` ne redémarre pas lui-même le service.
- Lors du chargement de `translation.env`, `crontab.sh` référence `${expiry_date}` avant de calculer cette variable ; le message de renouvellement peut donc ne pas afficher la date attendue.
- Les scripts utilisent des chemins relatifs pour charger leur configuration ; le répertoire courant doit contenir les fichiers attendus lors de leur exécution, notamment depuis cron.

Le contrôle conditionnel de `MaxDays` est maintenant actif : Certbot n'est lancé par `crontab.sh` que si le certificat existant expire dans le seuil configuré. Les limites restantes doivent toutefois être traitées et testées avant une activation en production.
