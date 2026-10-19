#!/bin/bash

set +a
source config.env
source secrets.env

ACTION="$1"

WORKER_URL="${WorkerUrl}"
API_TOKEN="${ApiToken}"

case "$ACTION" in

  create)

     curl -s -X POST "${WORKER_URL}/dns" \
      -H "X-API-Token: ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"fqdn\":\"_acme-challenge.${CERTBOT_DOMAIN}\",
        \"value\":\"${CERTBOT_VALIDATION}\"
      }"

    sleep "${CoolDownBeforeCheckChallenge}"
    ;;


  delete)

    curl -s -X DELETE "${WORKER_URL}/dns" \
      -H "X-API-Token: ${API_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"fqdn\":\"_acme-challenge.${CERTBOT_DOMAIN}\",
        \"value\":\"${CERTBOT_VALIDATION}\"
      }"
    rm -f "${ACME_TOKEN}"
    ;;

esac