#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

# Variables
DB_NAME="library"
DB_USER="root"
DB_PASS="root"  # Replace with a secure password

echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo "Installing MySQL Server..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo "Starting and enabling MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

echo "Configuring MySQL for remote access..."
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

echo "Setting up MySQL database and user..."
sudo mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "Downloading library.sql file..."
curl -o library.sql https://github.com/PriyanSappal/java-spring-boot-app/blob/main/library.sql
echo "finished trying to dl library.sql file..."

echo "Seeding the database..."
sudo mysql -u $DB_USER -p$DB_PASS $DB_NAME < library.sql
echo "Database seeded successfully."

echo "MySQL Database VM setup is complete."
echo "Please ensure this VM's firewall allows access to MySQL on port 3306."