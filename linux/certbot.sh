#!/bin/bash

set +a
source config.env
source secrets.env
source translation.env

if [ ! -f "${LogsPath}" ]; then
    mkdir -p "$(dirname "${LogsPath}")"
    touch "${LogsPath}"
fi

LOG_FILE="${LogsPath}"

if certbot certonly \
        --register-unsafely-without-email \
        --force-renewal \
        --manual \
        --preferred-challenges dns \
        --manual-auth-hook "${AcmeScriptPath} create" \
        --manual-cleanup-hook "${AcmeScriptPath} delete" \
        --eab-kid "${EabKid}" \
        --eab-hmac-key "${EabHmac}" \
        --server "${ServerUrl}" \
        --config-dir "${CertificatsPath}" \
        -d "${Domain}"

then
    echo "[$(date)] -   INFO    -   ${CertificatSuccessRenewal}" >> "${LOG_FILE}"
else
    echo "[$(date)] -   INFO    -   ${CertificatRenewalFailed}" >> "${LOG_FILE}"

    # Gestion d'erreur
    exit 1
fi