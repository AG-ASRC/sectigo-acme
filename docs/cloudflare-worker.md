# Cloudflare Worker

Le Worker (`cloudflare/worker.js`) expose une petite API utilisée par les hooks Linux et Windows pour créer puis supprimer les enregistrements TXT du challenge ACME DNS-01. Il ne remplace pas les scripts clients et ne contient aucune configuration propre à un domaine.

## Routes

| Méthode et chemin | Authentification | Comportement |
| --- | --- | --- |
| `GET /health` | Aucune | Répond `200` avec `{"status":"ok"}`. Cette route sert uniquement au contrôle de disponibilité. |
| `POST /dns` | `X-API-Token` | Crée un TXT `_acme-challenge` avec le contenu fourni. Un enregistrement de même nom et de même valeur est considéré comme déjà créé. Le TTL est fixé à 120 secondes. |
| `DELETE /dns` | `X-API-Token` | Recherche le TXT par nom et supprime les enregistrements dont le contenu correspond exactement à la valeur reçue. |
| `OPTIONS` | Aucune | Répond `204` pour les requêtes de pré-vérification CORS. |

Les requêtes DNS doivent avoir `Content-Type: application/json` et un corps de cette forme, y compris pour `DELETE` :

```json
{
  "fqdn": "_acme-challenge.example.com",
  "value": "valeur-du-challenge-acme"
}
```

Le hook Linux construit le nom à partir de `CERTBOT_DOMAIN` et `CERTBOT_VALIDATION`. Le hook Windows transmet `RecordName` et `Token`. Les deux ajoutent le préfixe `_acme-challenge.` et envoient le jeton partagé dans l'en-tête `X-API-Token`.

Les réponses de succès sont des objets JSON avec `success: true`. La création retourne un `record_id` (ou `message: "Record already exists"` si la valeur existe déjà); la suppression retourne notamment le nombre d'enregistrements supprimés. Les erreurs courantes utilisent les statuts `400` (JSON ou paramètres invalides), `401` (jeton absent ou invalide), `403` (nom hors préfixe autorisé), `404` (zone introuvable) et `500` (erreur de l'API Cloudflare ou création/liste impossible).

## Configuration requise

Configurer ces deux secrets dans l'environnement du Worker Cloudflare :

| Nom | Utilisation |
| --- | --- |
| `ACME_TOKEN` | Jeton partagé attendu dans `X-API-Token` pour les opérations protégées. Il doit correspondre à `ApiToken` dans les secrets des clients Linux et Windows. |
| `CF_API_TOKEN` | Jeton Cloudflare utilisé par le Worker pour rechercher les zones, lire les TXT et créer/supprimer les enregistrements. |

Le jeton `CF_API_TOKEN` doit avoir les permissions `Zone:Read`, `DNS:Read` et `DNS:Edit`, limitées aux seules zones nécessaires. Il est utilisé comme secret (`Bearer`), jamais transmis par les hooks.

Côté clients, configurer également l'URL de déploiement du Worker (`WorkerUrl` dans `linux/config.env` ou `WorkerURL` dans `windows/config.ini`) et le même `ApiToken` dans `linux/secrets.env` et `windows/secrets.ini`. Les variables Sectigo EAB restent indépendantes de la configuration Cloudflare.

Ne placez aucun secret dans le code source, le README, un fichier `.example` ou l'URL du Worker. Utilisez le mécanisme de secrets de Cloudflare et protégez les fichiers de secrets clients.

## Restrictions et limites

- Les opérations DNS acceptent uniquement les noms qui commencent par `_acme-challenge.`. Le Worker ne vérifie toutefois pas que le suffixe est un nom de domaine complet valide ni qu'il appartient à une liste autorisée. La portée effective est donc déterminée par les zones accessibles au `CF_API_TOKEN`.
- `GET /health` est public. Les réponses CORS autorisent toutes les origines (`*`); CORS n'est pas un mécanisme d'authentification. Le jeton partagé protège `POST /dns` et `DELETE /dns`.
- La suppression cible uniquement les TXT dont le contenu correspond exactement à `value`; d'autres valeurs présentes sous le même nom ne sont pas supprimées.
- Le corps JSON de `DELETE` doit être valide. Contrairement à `POST`, son erreur de décodage n'est pas convertie explicitement en réponse `400`.
- Le Worker fixe le TTL des nouveaux TXT à 120 secondes et ne permet pas de le configurer depuis les hooks.
- Le Worker ne met pas en oeuvre de limite de débit ni de contrôle d'identité distinct par client. Utilisez un jeton dédié, à privilèges minimaux et limité aux zones requises.

Pour le contrat côté hooks et le déroulement DNS-01, voir aussi les [guides Linux](linux.md) et [Windows](windows.md).
