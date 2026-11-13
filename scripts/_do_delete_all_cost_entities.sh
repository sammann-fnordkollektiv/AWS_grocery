#!/bin/bash

echo "[INFO] Delete all S3 buckets"
for bucket in $(aws s3api list-buckets \
--query "Buckets[].Name" \
--output text); do
    echo "[INFO] Delete bucket: $bucket"
    aws s3 rb s3://$bucket --force
done

echo "[INFO] Stop all EC2 instances"
# IDs of all running instances
INSTANCE_IDS=$(aws ec2 describe-instances \
--filters "Name=instance-state-name,Values=running" \
--query "Reservations[].Instances[].InstanceId" \
--output text)
if [ ! -z "$INSTANCE_IDS" ]; then
    echo "[INFO] Stop intance: $INSTANCE_IDS"
    aws ec2 stop-instances --instance-ids $INSTANCE_IDS
fi

echo "[INFO] Delete unused volumes"
for vol in $(aws ec2 describe-volumes \
--filters "Name=status,Values=available" \
--query "Volumes[].VolumeId" \
--output text); do
    echo "[INFO]: Delete volume: $vol"
    aws ec2 delete-volume --volume-id $vol
done

echo "[INFO] Delete elastic load balancers"
for clb in $(aws elb describe-load-balancers \
--query "LoadBalancerDescriptions[].LoadBalancerName" \
--output text); do
    echo "[INFO] Delete elastic load balancers: $elb"
    aws elb delete-load-balancer --load-balancer-name $elb
done

for lb in $(aws elbv2 describe-load-balancers \
--query "LoadBalancers[].LoadBalancerArn" \
--output text); do
    echo "[INFO] Delete Load Balancer: $lb"
    aws elbv2 delete-load-balancer --load-balancer-arn $lb
done

