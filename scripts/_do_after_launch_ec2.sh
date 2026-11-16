#!/usr/bin/env bash

# Copy n paste this file in AWS EC2 launch instance
# Debug? See /var/log/cloud-init-output.log

set -euo pipefail
#set -x

echo "#########################################################################"
echo " Start setup"
echo "#########################################################################"
export HOME="/home/ec2-user"
cd "${HOME}"
# breaks scp
#echo "Check init:" >> ~/.bashrc
#echo "cat /var/log/cloud-init-output.log" >> ~/.bashrc

if sudo dnf check-update --releasever=latest; then
  echo "[INFO]: There is no dist upgrade."
else
  status=$?
  if [[ $status -eq 100 ]]; then
    echo "[INFO]: There is a dist upgrade."
    echo "[INFO]: This is not productive environment."
    echo "[INFO]: Starting upgrade."
    echo "[INFO]: And rebooting."
    sudo dnf upgrade --releasever=latest -y
    echo "[INFO]: Reboot - results in new IP"
  fi
fi

sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade

echo "########################################################################"
echo " Install psql"
echo "########################################################################"
sudo yum install -y postgresql15-server postgresql15-contrib
if result=$(sudo postgresql-setup --initdb 2>&1); then
  echo "[INFO]: Database init successful."
else
  status=$?
  printf '[WARN] Database init failed with %s:\n%s\n' \
    "$status" "$result" >&2
fi
sudo systemctl enable --now postgresql
sudo sed -i '/^host/s/ident$/md5/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
systemctl status postgresql

echo "#########################################################################"
echo " Install docker"
echo "#########################################################################"
sudo yum -y install git docker
sudo systemctl enable --now docker
sudo systemctl status docker
sudo usermod -aG docker ec2-user
sudo systemctl is-active --quiet docker
sudo docker info

echo "########################################################################"
echo " Git AWS Grocery"
echo "########################################################################"
if git clone https://github.com/sammann-fnordkollektiv/AWS_grocery.git; then
  echo "[INFO]: Cloning git"
  git config --global --add safe.directory /home/ec2-user/AWS_grocery
else
  echo "[INFO]: Already cloned"
fi
cd AWS_grocery/
git checkout dockerize-2
git pull

echo "########################################################################"
echo " Initialize database - local AWS Grocery"
echo "########################################################################"
sudo yum -y install openssl
ENV_FILE="$(pwd)/backend/.env"
PORT=5432
PGPASSFILE="env/.pqpass"
INIT_FILE="etc/_do_init_db.sql"
POPULATE_FILE="backend/app/sqlite_dump_clean.sql"
export GROCERY_USER_PASSWORD="$(openssl rand -hex 6)"
echo "JWT_SECRET_KEY=$(openssl rand -hex 6)" > "${ENV_FILE}"
echo "POSTGRES_USER=grocery_user" >> "${ENV_FILE}"
echo "POSTGRES_PASSWORD=${GROCERY_USER_PASSWORD}" >> "${ENV_FILE}"
echo "POSTGRES_DB=grocerymate_db" >> "${ENV_FILE}"
echo "POSTGRES_HOST=localhost" >> "${ENV_FILE}"
echo "POSTGRES_URI=postgresql://grocery_user:"${GROCERY_USER_PASSWORD}"@localhost:5432/grocerymate_db" >> "${ENV_FILE}"
chown ec2-user:ec2-user "${ENV_FILE}"

mkdir -p env
echo "127.0.0.1:${PORT}:grocery_user:${GROCERY_USER_PASSWORD}" >> "${PGPASSFILE}"
env | grep GROCERY_USER_PASSWORD
PGPASSFILE="${PGPASSFILE}" psql -h 127.0.0.1 -p "${PORT}" -U postgres -d postgres -f "${INIT_FILE}"
PGPASSFILE="${PGPASSFILE}" psql -h 127.0.0.1 -p "${PORT}" -U grocery_user -d grocerymate_db -f "${POPULATE_FILE}"
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
