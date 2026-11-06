#!/usr/bin/env bash
# Copy n paste this file in AWS EC2 launch instance
# Debug? See /var/log/cloud-init-output.log

sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade
sudo yum -y install git docker
sudo systemctl start docker
sudo systemctl enable docker
#sudo systemctl status docker
sudo systemctl restart docker
sudo usermod -aG docker ec2-user
sudo newgrp docker
# docker info
echo "ll='ls -la'" >> ~/.bash_aliases
source ~/.bash_aliases
git clone https://github.com/sammann-fnordkollektiv/AWS_grocery.git
cd AWS_grocery/
git checkout dockerize-2
bash ./etc/01-build-docker.sh
docker images
bash ./etc/02-run-docker.sh

