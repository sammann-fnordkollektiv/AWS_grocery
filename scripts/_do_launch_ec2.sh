#!/usr/bin/env bash

# TODO
# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html
PUBLIC_IP_FILE="${HOME}/Git/AWS_grocery/env/public.ip"
INSTANCE_FILE="${HOME}/Git/AWS_grocery/env/instance.json"
AFTER_LAUNCH="${HOME}/Git/AWS_grocery/scripts/_do_after_launch_ec2.sh"

if [ -f "${INSTANCE_FILE}" ]; then
    INSTANCE_ID=$(jq -r '.Instances[0].InstanceId' "${INSTANCE_FILE}") 
    echo "[INFO] Delete ${INSTANCE_ID}"
    aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}"
fi

echo "[INFO] Launch new instance"
aws ec2 run-instances \
    --image-id ami-0f3f7d98b433d3e84 \
    --count 1 \
    --instance-type t2.micro \
    --key-name "Deine erste EC2-Instanz starten" \
    --security-group-ids sg-0ad57bf49a7fc000e \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=my-aws-store}]' \
    --user-data file://"${AFTER_LAUNCH}" > "${INSTANCE_FILE}" 

echo "[INFO] Wait until new instance is ready"
INSTANCE_ID=$(jq -r '.Instances[0].InstanceId' "${INSTANCE_FILE}") 
aws ec2 wait instance-running --instance-ids "${INSTANCE_ID}"

echo "[INFO] Get puplic IP of new instance"
PUBLIC_IP=""
while [ "${PUBLIC_IP}" == "" ]; do
    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids "${INSTANCE_ID}" \
      --query 'Reservations[*].Instances[*].PublicIpAddress' \
      --output text)
    
    if [ "${PUBLIC_IP}" == "" ]; then
        echo "IP wird noch zugewiesen... warte 2 Sekunden..."
        sleep 2
    fi
done

echo "[INFO] Get puplic IP of new instance: ${PUBLIC_IP}"
echo "${PUBLIC_IP}" > "${PUBLIC_IP_FILE}"
