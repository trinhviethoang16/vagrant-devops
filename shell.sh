# Install Docker, NGINX, Java,...
apt-get update
apt-get install -y nginx net-tools docker docker-compose fontconfig openjdk-17-jre-headless

# Jenkins config
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
apt-get update
apt-get install -y jenkins

# Install MongoDB
apt-get install -y gnupg curl
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update
apt-get install -y mongodb-org
systemctl start mongod

#install MongoDB Shell
apt-get install -y mongodb-mongosh

###
systemctl restart docker.service

# Development enviroment config
cat <<EOL > /etc/nginx/sites-available/myapp-dev.conf
server {
    listen 3500;
    location / {
        proxy_pass http://127.0.0.1:3500;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL
ln -s /etc/nginx/sites-available/myapp-dev.conf /etc/nginx/sites-enabled/

# Production enviroment config
cat <<EOL > /etc/nginx/sites-available/myapp-prod.conf
server {
    listen 4000;
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOL
ln -s /etc/nginx/sites-available/myapp-prod.conf /etc/nginx/sites-enabled/

# Docker config
usermod -aG docker $USER
usermod -aG docker jenkins
newgrp docker
chmod 666 /var/run/docker.sock
systemctl restart containerd.service jenkins.service
docker stop frontend
docker rm frontend

# Development enviroment
docker pull trinhviethoang16/frontend:develop
docker run -d -p 3500:3000 trinhviethoang16/frontend:develop

# Production environment
docker pull trinhviethoang16/frontend:latest
docker run -d -p 4000:3000 trinhviethoang16/frontend:latest

# MongoDB config
mongosh --eval "db = db.getSiblingDB('user'); db.createUser({user: 'user1', pwd: 'password1', roles: [{role: 'readWrite', db: 'user'}]}); db.createUser({user: 'user2', pwd: 'password2', roles: [{role: 'readWrite', db: 'user'}]}); db.adminCommand({createUser: 'admin1', pwd: 'adminpassword', roles: [{role: 'userAdminAnyDatabase', db: 'admin'}]});"
