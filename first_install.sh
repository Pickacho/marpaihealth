#!/bin/bash
sudo yum update -y
sudo yum install -y yum-utils
sudo yum install docker -y
$USER
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 

$USER
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose
$USER
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
#Create the docker group.
$USER
groupadd docker
sudo service docker restart
#Add your user to the docker group 
sudo usermod -aG docker  ec2-user
# # #activate the changes to groups
echo "Before newgrp"
/usr/bin/newgrp docker <<EONG
echo "hello from within newgrp"
id
EONG
echo "After newgrp"
# newgrp docker
# # Test for working docker
docker run hello-world
mkdir -p /home/ec2-user/postgresql/data
mkdir -p /home/ec2-user/postgresql/pgadmin
mkdir -p  /home/ec2-user/jenkins/
chown -R  5050:5050 /home/ec2-user/postgresql/pgadmin

docker run  --rm  --name postgresql -e POSTGRES_USER=ran -e POSTGRES_PASSWORD=marpaihealth -p 5432:5432 -v /home/ec2-user/postgresql/data:/var/lib/postgresql/data -d postgres



docker run --rm --name my-pgadmin -p 80:80   --memory="0.3g" --cpus="0.3" -v /home/ec2-user/postgresql/pgadmin/var/lib/pgadmin/:/var/lib/pgadmin  -v "/home/ec2-user/postgresql/pgadmin/home/:$HOME"  -e 'PGADMIN_DEFAULT_EMAIL=admin@admin.admin' -e 'PGADMIN_DEFAULT_PASSWORD=postgresmaster' -d dpage/pgadmin4


#get postgresql container ip for PGadmin connection
containerIP=`docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' postgresql`
echo use $containerIP as postgres instance ip >> /tmp/postgres_internalip.log


wget https://raw.githubusercontent.com/Pickacho/marpaihealth/master/Dockerfile -O /home/ec2-user/jenkins/Dockerfile
cd /home/ec2-user/jenkins/
docker build -t myjenkins-blueocean:2.332.2-1 .

docker network create jenkins
docker run \
  --name jenkins-blueocean \
  --rm \
  --detach \
  --network jenkins \
  --env DOCKER_HOST=tcp://docker:2376 \
  --env DOCKER_CERT_PATH=/certs/client \
  --env DOCKER_TLS_VERIFY=1 \
  --publish 8080:8080 \
  --publish 50000:50000 \
  --volume jenkins-data:/var/jenkins_home \
  --volume jenkins-docker-certs:/certs/client:ro \
  --memory="0.6g" --cpus="0.6" \
  myjenkins-blueocean:2.332.2-1 

sleep 20 
 docker exec -it jenkins-blueocean  cat /var/jenkins_home/secrets/initialAdminPassword  ; echo ""

# docker run \
#   --name jenkins-docker \
#   --rm \
#   --detach \
#   --privileged \
#   --network jenkins \
#   --network-alias docker \
#   --env DOCKER_TLS_CERTDIR=/certs \
#   --volume /home/ec2-user/jenkins/jenkins-docker-certs:/certs/client \
#   --volume /home/ec2-user/jenkins/jenkins-data:/var/jenkins_home \
#   --publish 2376:2376 \
#   docker:dind \
#   --storage-driver overlay2




# cat << EOF > /home/ec2-user/jenkins/Dockerfile
# FROM jenkins/jenkins:2.332.2-jdk11
# USER root
# RUN apt-get update && apt-get install -y lsb-release
# RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
# https://download.docker.com/linux/debian/gpg
# RUN echo "deb [arch=$(dpkg --print-architecture) \
# signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
# https://download.docker.com/linux/debian \
# $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
# RUN apt-get update && apt-get install -y docker-ce-cli
# USER jenkins
# RUN jenkins-plugin-cli --plugins "blueocean:1.25.3 docker-workflow:1.28"
# EOF


#  1807b2090c00428581aff010c5c3fb2d