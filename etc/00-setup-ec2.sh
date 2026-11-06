sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade
sudo yum install git docker
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo systemctl restart docker
sudo usermod -aG docker ec2-user
newgrp docker
docker info
echo "ll='ls -la'" > ~/.bash_aliases
git clone https://github.com/sammann-fnordkollektiv/AWS_grocery.git
cd AWS_grocery/etc
bash 01-build-docker.sh
bash 02-run-docker.sh

