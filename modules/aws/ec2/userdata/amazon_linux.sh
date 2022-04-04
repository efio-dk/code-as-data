#!/bin/bash

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

# ecr login
aws ecr get-login-password --region ${aws_region} | docker login --username AWS --password-stdin ${aws_account}.dkr.ecr.${aws_region}.amazonaws.com

docker run --name nginx -p 80:80 -d nginx

%{ for command in commands ~}
$(${command})
%{ endfor ~}
