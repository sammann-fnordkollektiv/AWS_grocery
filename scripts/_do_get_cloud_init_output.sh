#!/usr/bin/env bash

echo "[INFO] Get cloud-init-output.log"
aws ec2 get-console-output \ 
--instance-id "${INSTANCE_ID}" \
--output text > cloud-init-output.log

