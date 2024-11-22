#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

# Variables
REPO_URL="https://github.com/PriyanSappal/java-spring-boot-app"
APP_DIR="repo"
DB_HOST=""  # Replace with the IP of the database VM
DB_PORT=3306
DB_NAME="library"
DB_USER="root"
DB_PASS="root"  # Replace with the password used in the database VM

echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y 
echo "Finished system update"

echo "Installing required packages..."
sudo DEBIAN_FRONTEND=noninteractive apt install -y openjdk-17-jdk maven git
echo "Finished all 3rd packages installs"

echo "Cloning the repository..."
git clone "$REPO_URL" $APP_DIR
echo "Finished git clone"

echo "Start Configuring application.properties File"
cat <<EOL > "$APP_DIR/LibraryProject2/src/main/resources/application.properties"
# spring.datasource.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/${DB_NAME}
# spring.datasource.username=${DB_USER}
# spring.datasource.password=${DB_PASS}
# spring.jpa.hibernate.ddl-auto=update
# server.port=5000

# Allow Spring Boot to initialize the database
spring.datasource.initialization-mode=always
spring.datasource.data=classpath:library.sql
EOL


echo "prepare before Seeding the database..."
mv /home/ubuntu/repo/library.sql /home/ubuntu/repo/LibraryProject2/src/main/resources
echo "finished Move of library.sql"

echo "Building and running the application..."
cd "$APP_DIR/LibraryProject2"
mvn spring-boot:run



echo "Application is running at http://$(hostname -I | awk '{print $1}'):8008"