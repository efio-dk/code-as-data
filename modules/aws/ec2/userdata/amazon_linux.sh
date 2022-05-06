#!/bin/bash

# Mount volumes
%{ for volume in volumes ~}
device=$(realpath ${volume.device_name})
mkfs -t xfs $device
mkdir -p ${volume.mountpoint}
mount $device ${volume.mountpoint}

%{ endfor ~}
# Volumes mounted

sudo yum update -y

# Add trusted ssh keys 
%{ for ssh_key in ssh_keys ~}
echo ${ssh_key} >> ~ec2-user/.ssh/authorized_keys
%{ endfor ~}

# Install docker image
# sudo yum install docker -y
sudo amazon-linux-extras install docker
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /bin/docker-compose
sudo chmod +x /bin/docker-compose

# ecr login
%{ for command in commands ~}
${command}
%{ endfor ~}
