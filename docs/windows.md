# Guide Windows

Cette configuration utilise PowerShell, win-acme (WACS), le magasin de certificats de l'ordinateur et IIS.

## Architecture et déroulement

1. La tâche planifiée créée par `windows/make-task.ps1` lance `task.ps1` chaque jour à 03:00 sous `SYSTEM`, avec le niveau de privilèges maximal.
2. `task.ps1` recherche le certificat correspondant à `WildcardDomains` dans `Cert:\LocalMachine\<CertificateStore>`.
3. Si le certificat est absent ou expire avant le seuil `MaxDays`, le script lance `certbot.ps1`. Sinon, il journalise qu'aucun renouvellement n'est requis.
4. `certbot.ps1` démarre WACS avec le plugin `certificatestore`. WACS contacte Sectigo et délègue le challenge DNS-01 à `acme-hook.ps1`.
5. Le hook crée et supprime l'enregistrement TXT auprès du Cloudflare Worker. Après l'émission, WACS stocke le certificat et `iis.ps1` met à jour les liaisons HTTPS du site IIS configuré.

Les événements de suivi sont écrits dans le journal Application Windows. Une exécution manuelle de `task.ps1` ou de WACS doit se faire dans une session élevée afin que le processus puisse accéder au magasin de certificats de l'ordinateur.

## Prérequis

- Windows PowerShell et le module `ScheduledTasks`.
- IIS et le module PowerShell `WebAdministration`.
- win-acme installé et accessible à l'emplacement défini dans `WACSPath`.
- Un compte Sectigo et ses identifiants External Account Binding (EAB).
- Un Cloudflare Worker capable de modifier les enregistrements DNS et son jeton API.

## Installation

1. Copiez `windows/config.ini.example` vers `windows/config.ini`.
2. Copiez `windows/secrets.ini.example` vers `windows/secrets.ini`.
3. Renseignez les paramètres ci-dessous ainsi que les identifiants EAB et le jeton Worker dans le fichier de secrets.
4. Vérifiez que tous les chemins configurés existent sur le serveur.
5. Depuis une session PowerShell administrateur, exécutez `windows/make-task.ps1`, puis démarrez la tâche planifiée pour valider l'installation.
6. Assurez-vous que le compte `SYSTEM` a accès aux scripts, à WACS et aux fichiers de configuration.

## Paramètres `config.ini`

| Clé | Fonction |
| --- | --- |
| `ServerUrl` | Endpoint ACME Sectigo. |
| `WildcardDomains` | Domaine demandé à Sectigo et motif utilisé pour retrouver le certificat. |
| `CertificateStore` | Magasin sous `Cert:\LocalMachine`, généralement `My`. Ce nom est transmis séparément du plugin WACS. |
| `CertificateFriendlyName` | Nom convivial configuré pour le certificat WACS. |
| `WorkerURL` | URL du Cloudflare Worker appelé par le hook. |
| `CoolDownBeforeCheckChallenge` | Attente en secondes après la création du TXT DNS-01. |
| `MaxDays` | Seuil d'expiration qui déclenche l'émission ou le renouvellement. |
| `IISSiteID` | Identifiant du site IIS à mettre à jour. |
| `WACSPath` | Chemin de `wacs.exe`. |
| `TaskPath`, `CertbotPath`, `AcmeHookPath`, `IISScriptPath` | Chemins des scripts utilisés dans le flux. |
| `TaskName`, `TaskDescription`, `EventSource` | Nom/description de la tâche et source du journal Application. |

Dans `secrets.ini`, renseignez `EabKid`, `EabHmac` et `ApiToken`. Ne partagez pas ce fichier et conservez les permissions les plus restrictives compatibles avec l'exécution sous `SYSTEM`.

## Scripts

| Script | Rôle |
| --- | --- |
| `windows/task.ps1` | Recherche le certificat, décide s'il faut émettre/renouveler et journalise le résultat. |
| `windows/certbot.ps1` | Construit les options WACS, lance l'émission et appelle la mise à jour IIS. |
| `windows/acme-hook.ps1` | Envoie les demandes DNS-01 au Worker. |
| `windows/iis.ps1` | Associe le certificat trouvé aux liaisons HTTPS du site sélectionné. |
| `windows/make-task.ps1` | Crée ou met à jour la tâche planifiée quotidienne. |
