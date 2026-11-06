#!/usr/bin/env bash

# Copy n paste this file in AWS EC2 launch instance
# Debug? See /var/log/cloud-init-output.log

set -exuo pipefail

echo "#################################################################"
echo " Start setup"
echo "#################################################################"
export HOME="/home/ec2-user"
cd "${HOME}"
echo "Check init:" >> ~/.bashrc
echo "cat /var/log/cloud-init-output.log" >> ~/.bashrc

sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade

# install psql
sudo yum install -y postgresql15-server postgresql15-contrib
sudo postgresql-setup --initdb
sudo systemctl enable --now postgresql
sudo sed -i '/^host/s/ident$/md5/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
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
su - ec2-user -c "git clone https://github.com/sammann-fnordkollektiv/AWS_grocery.git"
git config --global --add safe.directory /home/ec2-user/AWS_grocery
cd AWS_grocery/
git checkout dockerize-2

# Initiatlize aws-grocery database
ENV_FILE="$(pwd)/backend/.env"
export POSTGRES_PASSWORD="$(gpg --gen-random --armor 1 12)"
echo "JWT_SECRET_KEY=$(python3 -c 'import secrets; print(secrets.token_hex(32))')" > "${ENV_FILE}"
echo "POSTGRES_USER=grocery_user" >> "${ENV_FILE}"
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" >> "${ENV_FILE}"
echo "POSTGRES_DB=grocerymate_db" >> "${ENV_FILE}"
echo "POSTGRES_HOST=localhost" >> "${ENV_FILE}"
echo "POSTGRES_URI=postgresql://grocery_user:"${POSTGRES_PASSWORD}"@localhost:5432/grocerymate_db" >> "${ENV_FILE}"
chown ec2-user:ec2-user "${ENV_FILE}"

cd /tmp
sudo -u postgres psql -c "CREATE DATABASE grocerymate_db;"
sudo -u postgres psql -c "CREATE USER grocery_user WITH ENCRYPTED PASSWORD '${POSTGRES_PASSWORD}';"
sudo -u postgres psql -c "ALTER USER grocery_user WITH SUPERUSER;"
cd "${HOME}"

export PGPASSWORD="${POSTGRES_PASSWORD}"
psql -h localhost -U grocery_user -d grocerymate_db -f AWS_grocery/backend/app/sqlite_dump_clean.sql
psql -h localhost -U grocery_user -d grocerymate_db -c "SELECT * FROM users;"
psql -h localhost -U grocery_user -d grocerymate_db -c "SELECT * FROM products;"

cd "${HOME}/AWS_grocery"
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
--env POSTGRES_URI="postgresql://grocery_user:${POSTGRES_PASSWORD}@localhost:5432/grocerymate_db" \
--publish 5000:5000 \
--restart on-failure:5 \
grocerymate-app


# user env
echo "ll='ls -la'" >> ~/.bash_aliases
source ~/.bash_aliases



# SSH GITHUB
# git remote set-url origin git@github.com:sammann-fnordkollektiv/AWS_grocery.git
