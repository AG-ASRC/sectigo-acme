# Changelog

Ce fichier récapitule les changements notables du projet, du plus récent au plus ancien.

## [Unreleased]

### Ajouté

- Automatisation Windows de l'émission et du renouvellement de certificats Sectigo avec win-acme (WACS).
- Validation de domaine ACME par challenge DNS-01 : le hook PowerShell transmet la création et la suppression des enregistrements TXT à un Cloudflare Worker.
- Vérification quotidienne du certificat dans le magasin de certificats de l'ordinateur et déclenchement de l'émission si le certificat est absent.
- Déclenchement du renouvellement lorsque l'expiration approche du seuil configurable `MaxDays`.
- Enregistrement du certificat dans le magasin Windows sélectionné et mise à jour de la liaison HTTPS du site IIS configuré.
- Journalisation des événements de création, de renouvellement, d'absence de certificat et d'erreur dans le journal Application de Windows.
- Tâche planifiée quotidienne exécutée sous `SYSTEM` avec le niveau de privilèges maximal.
- Modèles de configuration `config.ini.example` et `secrets.ini.example`, avec exclusion des fichiers locaux contenant la configuration et les secrets.
- Documentation de l'architecture, des prérequis, de l'installation et des responsabilités de chaque script Windows dans le README.

### Modifié

- Séparation du plugin WACS (`certificatestore`) et du magasin cible (`CertificateStore`, par défaut `My`).
- Chargement des paramètres Windows avec préservation des antislashs dans les chemins de fichiers.
- Résolution de l'exécutable WACS, des scripts et du répertoire de travail à partir des chemins configurés.
- Mise à jour de la tâche planifiée existante possible via `make-task.ps1`.

### Corrigé

- L'absence de certificat n'interrompt plus le contrôle : elle déclenche une demande de création.
- Suppression d'une clé de traduction en double qui empêchait le chargement de `translation.ini`.
- Formatage des messages de journalisation utilisant le domaine, le magasin et le nombre de jours avant expiration.

### Limitations connues

- Le Cloudflare Worker est un service externe : son code n'est pas inclus dans le dépôt.
- Les scripts et la procédure d'installation Linux ne sont pas encore présents.
