# Changelog

Ce fichier suit les principes de [Keep a Changelog](https://keepachangelog.com/) et le versionnement sémantique. Chaque version utilise la même structure : `Added`, `Changed`, `Fixed`, `Security`, `Deprecated` et `Removed`.

## [1.4.0] - 2026-10-19

Documentation du Cloudflare Worker utilisé pour les challenges DNS-01.

### Added

- Worker Cloudflare pour créer et supprimer les enregistrements TXT des challenges DNS-01.
- Documentation dédiée des routes, du format des requêtes, des restrictions et des secrets nécessaires au Worker.
- Références au code et à la documentation du Worker depuis le README.

### Changed

- README mis à jour pour indiquer que l'implémentation du Worker est incluse dans le dépôt.

### Fixed

- Aucun correctif distinct dans cette version.

### Security

- Aucun changement de sécurité dans cette version.

### Deprecated

- Aucun élément déprécié.

### Removed

- Aucune fonctionnalité retirée.

## [1.3.0] - 2026-10-15

Automatisation Linux et documentation multiplateforme.

### Added

- Parcours Linux basé sur Certbot pour demander des certificats Sectigo avec validation DNS-01 via Cloudflare Worker.
- Scripts cron Linux, modèles de configuration et de secrets, et guides de documentation séparés par plateforme.
- Schéma d'architecture multiplateforme dans le README.

### Changed

- `crontab.sh` contrôle l'expiration selon `MaxDays` avant d'appeler `CerbotPath`.
- README recentré sur la vue d'ensemble et les guides Windows/Linux.
- Documentation Linux mise à jour pour décrire les scripts présents et leurs limites.

### Fixed

- Référence à `CerbotPath` dans le contrôle cron harmonisée avec la clé du modèle Linux.

### Security

- Aucun changement de sécurité dans cette version.

### Deprecated

- Aucun élément déprécié.

### Removed

- Ancienne indication selon laquelle l'automatisation Linux était absente.
- Instructions détaillées des plateformes retirées du README et déplacées vers des guides dédiés.

## [1.2.0] - 2026-10-15

### Added

- Paramètre `CertificateStore` pour configurer le magasin cible du certificat.

### Changed

- WACS sélectionne le plugin `certificatestore` séparément du magasin cible configuré.
- La documentation précise l'utilisation du magasin ordinateur et les privilèges requis.

### Fixed

- IIS associe maintenant le certificat en utilisant le magasin configuré.

### Security

- Aucun changement de sécurité dans cette version.

### Deprecated

- Aucun élément déprécié.

### Removed

- Dépendance au magasin IIS `WebHosting` imposé.

## [1.1.0] - 2026-10-14

### Added

- Émission et renouvellement des certificats Sectigo sous Windows avec win-acme (WACS).
- Validation ACME DNS-01 via un hook PowerShell et un Cloudflare Worker.
- Vérification quotidienne du certificat, émission lorsqu'il est absent et renouvellement au seuil `MaxDays`.
- Mise à jour des liaisons HTTPS IIS, journalisation des événements Windows et tâche planifiée sous `SYSTEM`.
- Modèles de configuration et de secrets Windows.

### Changed

- README complété avec l'architecture Windows, les prérequis et les instructions d'utilisation.

### Fixed

- Aucun correctif distinct dans cette version.

### Security

- Aucun changement de sécurité dans cette version.

### Deprecated

- Aucun élément déprécié.

### Removed

- Aucun élément retiré.

## [1.0.0] - 2026-10-14

### Added

- Initialisation du dépôt et ajout de la licence.

### Changed

- Aucun changement.

### Fixed

- Aucun correctif.

### Security

- Aucun changement de sécurité.

### Deprecated

- Aucun élément déprécié.

### Removed

- Aucun élément retiré.
