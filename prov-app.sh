#!/bin/bash

DB_PORT=3306
REPO_URL="https://PriyanSappal:${GITHUB_PAT}@github.com/PriyanSappal/java-spring-boot-app"

echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "Finished system update"

# Install Java 17
echo "Installing Java 17..."
sudo DEBIAN_FRONTEND=noninteractive apt install openjdk-17-jdk -y

# Set Java home environment variable and update the PATH
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Install Maven by downloading and extracting the binary
echo "Downloading and installing Apache Maven..."
wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz

# Extract Maven to the /opt directory
echo "Extracting Maven to /opt directory..."
sudo tar -xvzf apache-maven-*.tar.gz -C /opt

# Move extracted Maven to a more appropriate directory
echo "Moving Maven to /opt/maven..."
sudo mv /opt/apache-maven-* /opt/maven

# Export Maven environment variables
export M2_HOME=/opt/maven
export PATH=$M2_HOME/bin:$PATH


echo "Exporting environment variables"
export DB_USER="root"
export DB_PASS="password"
export DB_HOST=jdbc:mysql://${DB_IP}:$DB_PORT/library
echo "DB_HOST is: $DB_HOST"
echo "DB_NAME is: $DB_USER"
echo "DB_PASS is: $DB_PASS"

echo "Cloning the repository..."
git clone "$REPO_URL" repo
echo "Finished git clone"

echo "prepare before Seeding the database..."
mv repo/library.sql repo/LibraryProject2/src/main/resources
echo "finished Move of library.sql"


echo "Building and running the application..."
cd repo/LibraryProject2
sleep 5s
mvn clean package
mvn spring-boot:start

echo "[Completed. App should be running]"
