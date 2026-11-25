#!/bin/bash

set +a
source config.env
source translation.env

if [ ! -f "${LogsPath}" ]; then
    mkdir -p "$(dirname "${LogsPath}")"
    touch "${LogsPath}"
fi

ACME_JOB="0 3 * * * /bin/bash ${CrontabPath} > ${LogsPath} 2>&1 && ${ShellArgs}"

if ! crontab -l 2>/dev/null | grep -Fq "$ACME_JOB"; then
    (crontab -l 2>/dev/null; echo "$ACME_JOB") | crontab -
    echo "[$(date)] -   INFO    -   ${CrontabAdded}" >> "${LogsPath}"
else
    echo "[$(date)] -   INFO    -   ${CrontabAlreadyPresent}" >> "${LogsPath}"
fi