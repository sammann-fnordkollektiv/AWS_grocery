#!/usr/bin/env bash

# Copy n paste this file in AWS EC2 launch instance
# Debug? See /var/log/cloud-init-output.log

set -exuo pipefail

echo "#################################################################"
echo " Start setup"
echo "#################################################################"
sudo su - ec2-user
cd /home/ec2-user
echo "Check init:" >> ~/.bashrc
echo "cat /var/log/cloud-init-output.log" >> ~/.bashrc

sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade

# install psql
sudo dnf -y install postgresql15-server
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
systemctl status postgresql

# install docker
sudo yum -y install git docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo systemctl restart docker
sudo usermod -aG docker ec2-user
sudo newgrp docker
docker info

# Initialize aws-grocery
git clone https://github.com/sammann-fnordkollektiv/AWS_grocery.git
cd AWS_grocery/
git checkout dockerize-2

# Initiatlize aws-grocery database
ENV_FILE="$(pwd)/backend/.env"
export POSTGRES_PASSWORD="$(gpg --gen-random --armor 1 12)" >> "${ENV_FILE}"
echo "JWT_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')" >> "${ENV_FILE}"
echo "POSTGRES_USER=grocery_user" >> "${ENV_FILE}"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> "${ENV_FILE}"
echo "POSTGRES_DB=grocerymate_db" >> "${ENV_FILE}"
echo "POSTGRES_HOST=localhost" >> "${ENV_FILE}"
echo "POSTGRES_URI=postgresql://grocery_user:"${POSTGRES_PASSWORD}"@localhost:5432/grocerymate_db" >> "${ENV_FILE}"

sudo -i -u postgres
set -a
source "${ENV_FILE}"
set +a
psql -U postgres -c "CREATE DATABASE grocerymate_db;"
psql -U postgres -c "CREATE USER grocery_user WITH ENCRYPTED PASSWORD \'${POSTGRES_PASSWORD}\';"
psql -U postgres -c "ALTER USER grocery_user WITH SUPERUSER;"
exit

# Build aws-grocery docker
docker build \
--file "$(readlink -e backend/Dockerfile)" \
--tag grocerymate-app \
.
docker images

# Run aws-grocery docker
docker run \
--network host \
--env POSTGRES_HOST=localhost \
--env POSTGRES_URI=postgresql://grocery_user:"${POSTGRES_PASSWORD}"@localhost:5432/grocerymate_db \
--publish 5000:5000 \
--restart on-failure:5 \
grocerymate-app


# user env
echo "ll='ls -la'" >> ~/.bash_aliases
source ~/.bash_aliases



# SSH GITHUB
# git remote set-url origin git@github.com:sammann-fnordkollektiv/AWS_grocery.git
