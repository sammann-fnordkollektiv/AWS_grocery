sudo yum update -y
sudo yum install -y git python3 python3-pip postgresql15 postgresql15-server postgresql15-contrib
echo "$(date)" > ~/setup.log
git --version >> ~/setup.log
python3 --version >> ~/setup.log
pip --version >> ~/setup.log
psql --version >> ~/setup.log
sudo /usr/bin/postgresql-setup --initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
