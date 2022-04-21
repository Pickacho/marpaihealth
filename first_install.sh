/usr/bin/bash
sudo yum update -y
sudo yum install -y yum-utils
sudo yum install docker
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/local/bin/docker-compose
sudo chmod -v +x /usr/local/bin/docker-compose
sudo systemctl enable docker.service
sudo systemctl start docker.service
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
#Create the docker group.
sudo groupadd docker
#Add your user to the docker group 
sudo usermod -aG docker $USER
#activate the changes to groups
newgrp docker 
# Test for working docker
#docker run hello-world
mkdir /home/ec2-user/postgresql/data

docker run --name postgresql -e POSTGRES_USER=ran -e POSTGRES_PASSWORD=marpaihealth -p 5432:5432 -v /home/ec2-user/postgresql/data:/var/lib/postgresql/data -d postgres

mkdir /home/ec2-user/postgresql/pgadmin

docker run --name my-pgadmin -p 82:80  -e 'PGADMIN_DEFAULT_EMAIL=admin@admin.admin' -e 'PGADMIN_DEFAULT_PASSWORD=postgresmaster' -d dpage/pgadmin4

# docker run --rm --name my-pgadmin -p 82:80  -v "/home/ec2-user/postgresql/pgadmin/var/lib/pgadmin/:/var/lib/pgadmin" \
# -v "$HOME:$HOME" \ -e 'PGADMIN_DEFAULT_EMAIL=admin@admin.admin' -e 'PGADMIN_DEFAULT_PASSWORD=postgresmaster' -d dpage/pgadmin4

#get postgresql container ip for PGadmin connection
docker inspect --format="{{json .NetworkSettings.Networks}}"  postgresql



docker network create jenkins

docker run \
  --name jenkins-docker \
  --rm \
  --detach \
  --privileged \
  --network jenkins \
  --network-alias docker \
  --env DOCKER_TLS_CERTDIR=/certs \
  --volume /home/ec2-user/jenkins/jenkins-docker-certs:/certs/client \
  --volume /home/ec2-user/jenkins/jenkins-data:/var/jenkins_home \
  --publish 2376:2376 \
  docker:dind \
  --storage-driver overlay2


cat << EOF > /home/ec2-user/jenkins/Dockerfile
  FROM jenkins/jenkins:2.332.2-jdk11
  USER root
  RUN apt-get update && apt-get install -y lsb-release
  RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc \
    https://download.docker.com/linux/debian/gpg
  RUN echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/usr/share/keyrings/docker-archive-keyring.asc] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
  RUN apt-get update && apt-get install -y docker-ce-cli
  USER jenkins
  RUN jenkins-plugin-cli --plugins "blueocean:1.25.3 docker-workflow:1.28"
EOF
docker build -t myjenkins-blueocean:2.332.2-1 .

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
  myjenkins-blueocean:2.332.2-1 


 docker exec -it jenkins-blueocean  cat /var/jenkins_home/secrets/initialAdminPassword  ; echo ""
 
