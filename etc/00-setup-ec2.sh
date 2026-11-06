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
cd AWS_grocery
sudo cp etc/aws-grocery.service /etc/systemd/aws-grocery.service
sudo systemctl demon-reload
sudo systemctl enable --now aws-grocery.service
sudo systemctl status aws-grocery.service

