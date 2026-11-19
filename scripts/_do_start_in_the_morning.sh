#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="eu-central-1"
EC2_NAME="my-aws-store"       # Exakter Wert des EC2-Tags Name
RDS_ID="database-1"     # RDS-Instanz- oder Aurora-Cluster-Kennung

########################################################################

sudo apt update
sudo apt install -y awscli jq
aws configure


export AWS_DEFAULT_REGION="$AWS_REGION"

# EC2: anhand des Name-Tags suchen und Eindeutigkeit prüfen
EC2_IDS=$(aws ec2 describe-instances \
  --filters \
    "Name=tag:Name,Values=$EC2_NAME" \
    "Name=instance-state-name,Values=stopped,running,pending,stopping" \
  --query 'Reservations[].Instances[].InstanceId' \
  --output text)

read -r -a EC2_ARRAY <<< "$EC2_IDS"

if [[ ${#EC2_ARRAY[@]} -ne 1 || -z "${EC2_ARRAY[0]}" ]]; then
  echo "Fehler: Für EC2 Name='$EC2_NAME' wurde nicht genau eine passende Instanz gefunden."
  exit 1
fi

EC2_ID="${EC2_ARRAY[0]}"
echo "EC2 gefunden: $EC2_ID"

EC2_STATE=$(aws ec2 describe-instances \
  --instance-ids "$EC2_ID" \
  --query 'Reservations[0].Instances[0].State.Name' \
  --output text)

if [[ "$EC2_STATE" == "stopped" ]]; then
  aws ec2 start-instances --instance-ids "$EC2_ID"
else
  echo "EC2 ist bereits im Zustand: $EC2_STATE"
fi

# Erst prüfen, ob die Kennung zu einem RDS-Cluster (z. B. Aurora) gehört
CLUSTER=$(aws rds describe-db-clusters \
  --db-cluster-identifier "$RDS_ID" \
  --query 'DBClusters[0].[DBClusterIdentifier,Status]' \
  --output text 2>/dev/null || true)

if [[ -n "$CLUSTER" && "$CLUSTER" != "None" ]]; then
  read -r CLUSTER_ID CLUSTER_STATUS <<< "$CLUSTER"
  echo "RDS-Cluster gefunden: $CLUSTER_ID ($CLUSTER_STATUS)"

  if [[ "$CLUSTER_STATUS" == "stopped" ]]; then
    aws rds start-db-cluster --db-cluster-identifier "$CLUSTER_ID"
  else
    echo "RDS-Cluster ist bereits im Zustand: $CLUSTER_STATUS"
  fi
else
  # Andernfalls als normale RDS-DB-Instanz behandeln
  DB=$(aws rds describe-db-instances \
    --db-instance-identifier "$RDS_ID" \
    --query 'DBInstances[0].[DBInstanceIdentifier,DBInstanceStatus]' \
    --output text 2>/dev/null || true)

  if [[ -z "$DB" || "$DB" == "None" ]]; then
    echo "Fehler: Keine RDS-Instanz oder kein RDS-Cluster mit Kennung '$RDS_ID' gefunden."
    exit 1
  fi

  read -r DB_ID DB_STATUS <<< "$DB"
  echo "RDS-Instanz gefunden: $DB_ID ($DB_STATUS)"

  if [[ "$DB_STATUS" == "stopped" ]]; then
    aws rds start-db-instance --db-instance-identifier "$DB_ID"
  else
    echo "RDS-Instanz ist bereits im Zustand: $DB_STATUS"
  fi
fi

