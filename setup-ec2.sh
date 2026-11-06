sudo yum -y install screen
sudo yum -y update
sudo yum -y upgrade
sudo yum install git docker
git clone git https://github.com/sammann-fnordkollektiv/AWS_grocery.git
cd AWS_grocery
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker
sudo systemctl restart docker
sudo usermod -aG docker ec2-user
newgrp docker
docker info
./_do_build_and_run_docker.sh
