#!/usr/bin/env bash

HOST="${1}"

if [ -z "$HOST" ]; then
   HOST="public.ip"
fi

if [ -f "${HOST}" ]; then
    TEMP=$(tr -d '\r\n ' < "${HOST}") 
    HOST="${TEMP}"
fi

echo "${HOST}"
chromium "${HOST}":5000
ssh -o StrictHostKeyChecking=accept-new  -i ~/.ssh/msit.pem ec2-user@"${HOST}"
