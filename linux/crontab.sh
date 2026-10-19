#!/bin/bash

set +a
source config.env
source translation.env

if [ ! -f "${LogsPath}" ]; then
    mkdir -p "$(dirname "${LogsPath}")"
    touch "${LogsPath}"
fi

LOG_FILE="${LogsPath}"

CERT="${CertificatsPath}/live/${DomainOnly}/fullchain.pem"
RENEW_BEFORE_DAYS=${MaxDays}

expiry_date=$(openssl x509 -in "$CERT" -noout -enddate | cut -d= -f2)

expiry_epoch=$(date -d "$expiry_date" +%s)
current_epoch=$(date +%s)


if (( expiry_epoch <= current_epoch + (RENEW_BEFORE_DAYS * 86400) )); then
    echo "[$(date)] -   INFO    -   ${CertificatNeedRenewal}" >> "${LOG_FILE}"

    ${CerbotPath}
else
    echo "[$(date)] -   INFO    -   ${CertificatValidUntil}" >> "${LOG_FILE}"
fi