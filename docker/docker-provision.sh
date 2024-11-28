#!/bin/bash
set -e
# Variables
DB_NAME="library"
DB_USER="root"
DB_PASS="password"  # Replace with a secure password

# Update system packages
sudo apt-get update -y
sudo apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git curl apt-transport-https ca-certificates software-properties-common

# Installing MySQL to seed the database
echo "Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -y

echo "Starting and enabling MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

echo "Setting up MySQL database and user..."
sudo mysql -ppassword -e "CREATE DATABASE IF NOT EXISTS library; CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON library.* TO 'root'@'%'; FLUSH PRIVILEGES;"

# May need to change URL as token expires 
echo "Downloading library.sql file..."
cd ~
curl -H "Authorization: token ${GITHUB_PAT}" -o library.sql https://raw.githubusercontent.com/PriyanSappal/java-spring-boot-app/refs/heads/main/library.sql?token=GHSAT0AAAAAACYJ4C47SBYGL66ZKDAGDYW6Z2IO6DQ

echo "Seeding the database..."
sudo mysql -u $DB_USER -p$DB_PASS $DB_NAME < library.sql
echo "Database seeded successfully."

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Create Docker Compose file
cd ~
cat <<EOF > docker-compose.yml
version: '3'
services:
  database:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: library
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - mysql-data:/var/lib/mysql
      - ./library.sql:/docker-entrypoint-initdb.d/library.sql
    ports:
      - "3306:3306"
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 3

  application:
    image: priyansappal1/java-app:v1
    container_name: spring-app
    depends_on:
      database:
        condition: service_healthy
    environment:
      - DB_HOST=jdbc:mysql://database:3306/library
      - DB_USER=root
      - DB_PASS=root
    ports:
      - "5000:5000"

volumes:
  mysql-data:
EOF

sudo systemctl stop mysql.service
# Start application with docker compose
sudo docker compose down -v
sudo docker compose up
