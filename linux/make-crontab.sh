#!/bin/bash

set +a
source config.env
source translation.env

if [ ! -f "${LogsPath}" ]; then
    mkdir -p "$(dirname "${LogsPath}")"
    touch "${LogsPath}"
fi

LOG_FILE="${LogsPath}"

ACME_JOB="0 3 * * * /bin/bash ${CrontabPath} > /dev/null 2>&1 && systemctl restart ${WebServer}"

if ! crontab -l 2>/dev/null | grep -Fq "$ACME_JOB"; then
    (crontab -l 2>/dev/null; echo "$ACME_JOB") | crontab -
    echo "[$(date)] -   INFO    -   ${CrontabAdded}" >> "${LOG_FILE}"
else
    echo "[$(date)] -   INFO    -   ${CrontabAlreadyPresent}" >> "${LOG_FILE}"
fi