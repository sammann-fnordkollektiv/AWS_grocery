#!/bin/bash

HOST="${1}"
RDS_ENDPOINT="${2}"
PUBLIC_IP_FILE="env/public.ip"
RDS_ENDPOINT_FILE="env/rds.endpoint"
SSH_KEY="~/.ssh/msit.pem"

#
# If HOST parameter passed, use that one
#

if [ -z "${HOST}" ]; then
   HOST="${PUBLIC_IP_FILE}"
fi

#
# if HOST parameter is a file, use content
#

if [ -f "${HOST}" ]; then
    TEMP=$(tr -d '\r\n ' < "${HOST}") 
    HOST="${TEMP}"
else
    exit 2
fi

if [ -z "${RDS_ENDPOINT}" ]; then
   HOST="${RDS_ENDPOINT_FILE}"
fi

if [ -f "${HOST}" ]; then
    TEMP=$(tr -d '\r\n ' < "${HOST}") 
    HOST="${TEMP}"
else
    exit 2
fi

echo "Will listen on localhost:15432"
ssh -N -L 15432:"${RDS_ENDPOINT}":5432 ec2-user@"${HOST}" -i "${SSH_KEY}" -v
