#!/usr/bin/env bash

########################################################################
# Copy n paste this file in AWS EC2 launch instance
# Debug? See /var/log/cloud-init-output.log
########################################################################

set -euo pipefail
#set -x

echo "#########################################################################"
echo " TODOS"
echo "#########################################################################"
# VARS
# YUMs

# TODO: This breaks scp. But information on manual ec2 login would be nice
#echo "Check init:" >> ~/.bashrc
#echo "cat /var/log/cloud-init-output.log" >> ~/.bashrc

# TODO user env
#echo "ll='ls -la'" >> .bash_aliases
#source ~/.bash_aliases

# TODO install direnv

# TODO SSH GITHUB
# git remote set-url origin git@github.com:sammann-fnordkollektiv/AWS_grocery.git

# TODO: sudo yum -y install screen

echo "#########################################################################"
echo " Handle OS"
echo "#########################################################################"
if sudo dnf check-update --releasever=latest; then
  echo "[INFO]: There is no dist upgrade"
else
  status=$?
  if [[ $status -eq 100 ]]; then
    echo "[INFO]: There is a dist upgrade"
    echo "[INFO]: This is not productive environment"
    echo "[INFO]: Starting upgrade"
    echo "[INFO]: And rebooting"
    sudo dnf upgrade --releasever=latest -y
    echo "[INFO]: Reboot - results in new IP"
  fi
fi

sudo yum -y upgrade
sudo yum -y update

echo "########################################################################"
echo " Handle git for AWS Grocery"
echo "########################################################################"
HOME="/home/ec2-user"
PROJECT_DIR="AWS_grocery"
sudo yum -y install git

cd "${HOME}"
if git clone https://github.com/sammann-fnordkollektiv/"${PROJECT_DIR}".git; then
  echo "[INFO]: Cloning git"
  git config --global --add safe.directory /home/ec2-user/"${PROJECT_DIR}"
else
  echo "[INFO]: Already cloned"
fi
cd "${HOME}/${PROJECT_DIR}"
git checkout dockerize-2
git pull

echo "########################################################################"
echo " Install psql and database"
echo "########################################################################"
PORT=5432
PGPASSFILE="env/.pgpass"
INIT_FILE="etc/_do_init_db.sql"
POPULATE_FILE="backend/app/sqlite_dump_clean.sql"
sudo yum install -y postgresql15-server postgresql15-contrib

if result=$(sudo postgresql-setup --initdb 2>&1); then
  echo "[INFO]: Database init successful"
else
  status=$?
  printf '[WARN] Database init failed with %s:\n%s\n' \
    "$status" "$result" >&2
fi
sudo systemctl enable --now postgresql
sudo sed -i '/^host/s/ident$/md5/' /var/lib/pgsql/data/pg_hba.conf
sudo systemctl restart postgresql
systemctl status postgresql --no-pager

sudo yum -y install openssl
# set psql postgres
export PG_NEW_PASSWORD="$(openssl rand -hex 6)"
BACK_TO_THIS_PWD="$(pwd)"
cd /tmp
sudo --preserve-env=PG_NEW_PASSWORD -u postgres psql \
  -X -v ON_ERROR_STOP=1 -d postgres <<'SQL'
\getenv new_password PG_NEW_PASSWORD
ALTER ROLE postgres PASSWORD :'new_password';
SQL
echo "[INFO] Segrt postgres password"
cd "${BACK_TO_THIS_PWD}"
# set grocery_user postgres
export GROCERY_USER_PASSWORD="$(openssl rand -hex 6)"
ENV_FILE="$(pwd)/backend/.env"
echo "[INFO] Create environment file ${ENV_FILE} for local psql"
echo "JWT_SECRET_KEY=$(openssl rand -hex 6)" > "${ENV_FILE}"
echo "POSTGRES_USER=grocery_user" >> "${ENV_FILE}"
echo "POSTGRES_PASSWORD=${GROCERY_USER_PASSWORD}" >> "${ENV_FILE}"
echo "POSTGRES_DB=grocerymate_db" >> "${ENV_FILE}"
echo "POSTGRES_HOST=localhost" >> "${ENV_FILE}"
echo "POSTGRES_URI=postgresql://grocery_user:"${GROCERY_USER_PASSWORD}"@localhost:5432/grocerymate_db" >> "${ENV_FILE}"
chown ec2-user:ec2-user "${ENV_FILE}"
echo "[INFO] Set PGPPASSFILE ${PGPASSFILE}"
mkdir -p env
echo "" > "${PGPASSFILE}"
# * = same password for all databases
echo "127.0.0.1:${PORT}:*:postgres:${PG_NEW_PASSWORD}" >> "${PGPASSFILE}"
echo "127.0.0.1:${PORT}:*:grocery_user:${GROCERY_USER_PASSWORD}" >> "${PGPASSFILE}"
chmod 600 "${PGPASSFILE}"
echo "[INFO] init aws-grocery database"
PGPASSFILE="${PGPASSFILE}" \
GROCERY_USER_PASSWORD="${GROCERY_USER_PASSWORD}" \
psql -h 127.0.0.1 -p "${PORT}" -U postgres -d postgres -f "${INIT_FILE}"
echo "[INFO] populate aws-grocery database"
PGPASSFILE="${PGPASSFILE}" \
GROCERY_USER_PASSWORD="$GROCERY_USER_PASSWORD" \
psql -h 127.0.0.1 -p "${PORT}" -U grocery_user -d grocerymate_db -f "${POPULATE_FILE}"
echo "[INFO] check aws-grocery database"
PGPASSFILE="${PGPASSFILE}" \
psql -h 127.0.0.1 -p "${PORT}" -U grocery_user -d grocerymate_db -c "SELECT * FROM users;"
PGPASSFILE="${PGPASSFILE}" \
psql -P pager=off -h 127.0.0.1 -p "${PORT}" -U grocery_user -d grocerymate_db -c "SELECT * FROM products;"
unset PG_NEW_PASSWORD

echo "#########################################################################"
echo " All the docker"
echo "#########################################################################"
sudo yum -y install docker
sudo systemctl enable --now docker
sudo systemctl status docker --no-pager
sudo usermod -aG docker ec2-user
sudo systemctl is-active docker --no-pager
sudo docker info | cat

DOCKERFILE="backend/Dockerfile"
# Build aws-grocery docker
cd ~/AWS_grocery
pwd
whoami
docker build -f "${DOCKERFILE}" -t grocerymate-app .

docker images

# Run aws-grocery docker
docker run \
--network host \
--env POSTGRES_HOST=localhost \
--env POSTGRES_URI="postgresql://grocery_user:${GROCERY_USER_PASSWORD}@localhost:${PORT}/grocerymate_db" \
--publish 5000:5000 \
--restart on-failure:5 \
grocerymate-app
