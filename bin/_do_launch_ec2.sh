#!/usr/bin/env bash

if [ -f "instance.json" ]; then
    INSTANCE_ID=$(jq -r '.Instances[0].InstanceId' instance.json) 
    echo "[INFO] Delete ${INSTANCE_ID}"
    aws ec2 terminate-instances --instance-ids "${INSTANCE_ID}"
fi

echo "[INFO] Launch new instance"
aws ec2 run-instances \
    --image-id ami-01376afa3e7def694 \
    --count 1 \
    --instance-type t2.micro \
    --key-name "Deine erste EC2-Instanz starten" \
    --security-group-ids sg-0ad57bf49a7fc000e \
    --user-data file://etc/00-setup-ec2.sh > instance.json

echo "[INFO] Wait until new instance is ready"
INSTANCE_ID=$(jq -r '.Instances[0].InstanceId' instance.json) 
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
echo "${PUBLIC_IP}" > public.ip

