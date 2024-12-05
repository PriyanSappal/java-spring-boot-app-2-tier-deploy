#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

# Variables
DB_NAME="library"
DB_USER="root"
DB_PASS="password"  # Replace with a secure password

echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -y

echo "Starting and enabling MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

echo "Setting up MySQL database and user..."
sudo mysql -ppassword -e "CREATE DATABASE IF NOT EXISTS library; CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'password'; GRANT ALL PRIVILEGES ON library.* TO 'root'@'%'; FLUSH PRIVILEGES;"

echo "Downloading library.sql file..."
curl -H "Authorization: token ${GITHUB_PAT}" -o library.sql https://raw.githubusercontent.com/PriyanSappal/java-spring-boot-app/refs/heads/main/library.sql?token=GHSAT0AAAAAACYJ4C463P2FW4XLDPMN3MEGZ2PDQ7A
echo "finished downloading library.sql file..."

echo "Seeding the database..."
sudo mysql -u $DB_USER -p$DB_PASS $DB_NAME < library.sql
echo "Database seeded successfully."

echo "Configuring MySQL for remote access..."
sudo sed -i 's/\s*bind-address\s*=\s*127.0.0.1\s*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

echo "MySQL Database VM setup is complete."
echo "Please ensure this VM's firewall allows access to MySQL on port 3306."

