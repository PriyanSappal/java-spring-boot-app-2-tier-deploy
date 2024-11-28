# DevOps Project - 2-Tier Deployment of ‘Library’ Java Spring Boot App
- [DevOps Project - 2-Tier Deployment of ‘Library’ Java Spring Boot App](#devops-project---2-tier-deployment-of-library-java-spring-boot-app)
- [Stage 2: Local Deployment of a Java Spring Boot Application with MySQL](#stage-2-local-deployment-of-a-java-spring-boot-application-with-mysql)
  - [Prerequisites](#prerequisites)
  - [Step 1: Install MySQL Database](#step-1-install-mysql-database)
  - [Step 2: Verify Versions of Software Downloaded](#step-2-verify-versions-of-software-downloaded)
  - [Step 3: Export the environment variables](#step-3-export-the-environment-variables)
  - [Step 4: Start the application](#step-4-start-the-application)
  - [Step 5: Check the webpage](#step-5-check-the-webpage)
- [Stage 3: Automated Deployment using User Data](#stage-3-automated-deployment-using-user-data)
- [Explanation of Terraform Script - to provision the EC2 instances](#explanation-of-terraform-script---to-provision-the-ec2-instances)
  - [Key Considerations](#key-considerations)
  - [Security Groups](#security-groups)
    - [Application Security Group](#application-security-group)
      - [Ingress Rules](#ingress-rules)
      - [Egress Rules](#egress-rules)
    - [Database Security Group](#database-security-group)
      - [Ingress Rules](#ingress-rules-1)
      - [Egress Rules](#egress-rules-1)
  - [EC2 Instances](#ec2-instances)
    - [Database Instance](#database-instance)
    - [Application Instance](#application-instance)
  - [Notes](#notes)
  - [Conclusion](#conclusion)
    - [**1. Application Server (EC2 Instance)**](#1-application-server-ec2-instance)
    - [**2. Database Server (EC2 Instance)**](#2-database-server-ec2-instance)
    - [**3. Networking and Security**](#3-networking-and-security)
    - [**4. Variables and Parameters**](#4-variables-and-parameters)
  - [Application](#application)
    - [**App Provisioning Script**](#app-provisioning-script)
      - [**1. Set the GitHub Repository URL**](#1-set-the-github-repository-url)
      - [**2. Package Update and Upgrade**](#2-package-update-and-upgrade)
      - [**3. Install Java 17**](#3-install-java-17)
      - [**4. Set Java Home Environment Variable**](#4-set-java-home-environment-variable)
      - [**5. Install Maven**](#5-install-maven)
      - [**6. Configure Maven Environment Variables**](#6-configure-maven-environment-variables)
      - [**7. Set Database Connection Variables**](#7-set-database-connection-variables)
      - [**8. Clone the GitHub Repository**](#8-clone-the-github-repository)
      - [**9. Navigate to the Project Directory**](#9-navigate-to-the-project-directory)
      - [**10. Wait for Database to Be Ready**](#10-wait-for-database-to-be-ready)
      - [**11. Build the Project**](#11-build-the-project)
      - [**12. Start the Spring Boot Application**](#12-start-the-spring-boot-application)
    - [**Summary**](#summary)
  - [Database](#database)
    - [**Database Provisioning Script**](#database-provisioning-script)
- [Stage 4: Deploy the app and database on AWS or Azure using containers running on a Virtual Machine (Docker Compose). Automate it via Bash provision scripts that work in user data. (1-2 days).](#stage-4-deploy-the-app-and-database-on-aws-or-azure-using-containers-running-on-a-virtual-machine-docker-compose-automate-it-via-bash-provision-scripts-that-work-in-user-data-1-2-days)
  - [Pre-requisite information](#pre-requisite-information)
  - [Step 1: Using Dockerfile we first build an image.](#step-1-using-dockerfile-we-first-build-an-image)
  - [Step 2: Using `docker-compose.yml` to connect this with our MYSQL DB.](#step-2-using-docker-composeyml-to-connect-this-with-our-mysql-db)
  - [Step 3: Launching an EC2 instance using terraform.](#step-3-launching-an-ec2-instance-using-terraform)
  - [Blockers](#blockers)

# Stage 2: Local Deployment of a Java Spring Boot Application with MySQL

This guide will walk you through the steps to deploy your Java Spring Boot application locally with a MySQL database.

## Prerequisites
- Java 17 or later installed
- Spring Boot application files (including `application.properties`)
- Put the application in a Private GitHub Repo
- MySQL database installed locally
- Maven(depending on your project build tool)

## Step 1: Install MySQL Database
1. **Download and install MySQL**: If you don't already have MySQL installed, you can download it from [here](https://dev.mysql.com/downloads/installer/).
2. **Start the MySQL service**: Make sure the MySQL service is running on your local machine.

    ```bash
    sudo service mysql start  # On Linux systems
    ```

3. **Create a new database for the application**: Log into MySQL and create a new database.

    ```bash
    mysql -u root -p
    CREATE DATABASE my_database;
    EXIT;
    ```
## Step 2: Verify Versions of Software Downloaded 
If these do not come up set them up in environment variables within `PATH`.
1. `java --version`
2. `mvn --version`
3. `mysql --version`

## Step 3: Export the environment variables
1) `export DB_HOST="jdbc:mysql://localhost:3306/library"`
2) `export DB_USER=root`
3) `export DB_USER=root`

## Step 4: Start the application
Using the `mvn spring-boot:run` command. 

## Step 5: Check the webpage
* For the front page: http://localhost:5000/
* For the database (editable): http://localhost:5000/web/authors

# Stage 3: Automated Deployment using User Data
Using Terraform to provision the infrastructure.


# Explanation of Terraform Script - to provision the EC2 instances
[main.tf](main.tf) - Full script to provision the app and db. 

## Key Considerations

1. **NEVER Hardcode AWS Keys**:  
   Avoid hardcoding sensitive information such as `AWS_ACCESS_KEY` and `AWS_SECRET_KEY` directly in your script.

2. **HCL Syntax**:  
   Terraform uses a `key = value` format in its HashiCorp Configuration Language (HCL).

3. **Provider Configuration**:  
   The `provider` block specifies the cloud provider (AWS in this case) and the region for resource creation.

```hcl
provider "aws" {
  region = var.aws_region
}
```

## Security Groups

### Application Security Group
Defines the security group (`ps_app_sg`) to control access for the application.

```hcl
resource "aws_security_group" "ps_app_sg" {
  name        = "tech264-priyan-tf-app-sg-2"
  description = "Allow SSH and HTTP traffic"
}
```

#### Ingress Rules
- **Allow SSH (Port 22):**
  ```hcl
  resource "aws_vpc_security_group_ingress_rule" "app_allow_ssh_22" {
    security_group_id = aws_security_group.ps_app_sg.id
    from_port         = 22
    ip_protocol       = "tcp"
    to_port           = 22
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "App_Allow_SSH" }
  }
  ```

- **Allow HTTP (Port 5000):**
  ```hcl
  resource "aws_vpc_security_group_ingress_rule" "allow_5000" {
    security_group_id = aws_security_group.ps_app_sg.id
    from_port         = 5000
    ip_protocol       = "tcp"
    to_port           = 5000
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "App_Allow_5000" }
  }
  ```

#### Egress Rules
- **Allow All Outbound Traffic:**
  ```hcl
  resource "aws_vpc_security_group_egress_rule" "app_allow_out_all" {
    security_group_id = aws_security_group.ps_app_sg.id
    ip_protocol       = "All"
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "Allow_Out_all" }
  }
  ```

### Database Security Group
Defines the security group (`ps_db_sg`) to control database access.

```hcl
resource "aws_security_group" "ps_db_sg" {
  name        = "tech264-priyan-tf-db-sg"
  description = "Allow SSH and MySQL traffic"
}
```

#### Ingress Rules
- **Allow SSH (Port 22):**
  ```hcl
  resource "aws_vpc_security_group_ingress_rule" "db_allow_ssh_22" {
    security_group_id = aws_security_group.ps_db_sg.id
    from_port         = 22
    ip_protocol       = "tcp"
    to_port           = 22
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "Db_Allow_SSH" }
  }
  ```

- **Allow MySQL (Port 3306):**
  ```hcl
  resource "aws_vpc_security_group_ingress_rule" "allow_3306" {
    security_group_id = aws_security_group.ps_db_sg.id
    from_port         = 3306
    ip_protocol       = "tcp"
    to_port           = 3306
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "Db_Allow_5000" }
  }
  ```

#### Egress Rules
- **Allow All Outbound Traffic:**
  ```hcl
  resource "aws_vpc_security_group_egress_rule" "db_allow_out_all" {
    security_group_id = aws_security_group.ps_db_sg.id
    ip_protocol       = "All"
    cidr_ipv4         = var.allowed_cidr_blocks
    tags = { Name = "Db_Allow_Out_all" }
  }
  ```

## EC2 Instances

### Database Instance
Creates a database EC2 instance with the following specifications:

```hcl
resource "aws_instance" "db_instance" {
  ami                         = var.ami_id
  instance_type               = var.db_instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ps_db_sg.id]
  key_name                    = var.key_name
  user_data                   = templatefile("prov-db.sh", { GITHUB_PAT = var.pat })
  tags = { Name = "tech264-priyan-tf-java-db-instance" }
}
```
- Included the provision script in `user_data` and specified that the variable `GITHUB_PAT` in the `prov-db.sh` will be the set as the variable in `variable.tf`.

### Application Instance
Creates an application EC2 instance, which depends on the database instance:

```hcl
resource "aws_instance" "app_instance" {
  depends_on                  = [aws_instance.db_instance]
  ami                         = var.ami_id
  instance_type               = var.app_instance_type
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ps_app_sg.id]
  key_name                    = var.key_name
  user_data                   = templatefile("prov-app.sh", { DB_IP = aws_instance.db_instance.private_ip, GITHUB_PAT = var.pat })
  tags = { Name = "tech264-priyan-tf-java-app-instance" }
}
```
- Included reference to the `DB private IP` to be in the `prov-app.sh`. 
  
## Notes
- **User Data:** Used for provisioning resources with shell scripts (`prov-db.sh` and `prov-app.sh`).
- **Variables:** Ensure all referenced variables (e.g., `var.aws_region`, `var.allowed_cidr_blocks`) are defined in your Terraform variable files or passed in during runtime.

## Conclusion
This script demonstrates best practices in creating secure and scalable AWS resources using Terraform.

### **1. Application Server (EC2 Instance)**

- **Security Group**: A security group for the application instance to control traffic flow.
  - Inbound rules allow:
    - SSH (port 22) from a defined CIDR range.
    - HTTP (port 5000) from the same CIDR range.
  - Outbound rule allows all traffic to any destination.

- **Application EC2 Instance**: The EC2 instance where the Java application will run.
  - Configures the instance with a specific AMI (Ubuntu 22.04), instance type, and SSH key pair.
  - User data is passed to provision the instance, including a GitHub token and database connection details.

### **2. Database Server (EC2 Instance)**

- **Security Group**: A security group for the database instance to control access to the database server.
  - Inbound rules allow:
    - SSH (port 22) from a defined CIDR range.
    - MySQL (port 3306) from the application server's security group.
  - Outbound rule allows all traffic to any destination.

- **Database EC2 Instance**: The EC2 instance for running the MySQL database.
  - Configures the instance with a specified AMI (Ubuntu 22.04), instance type, and SSH key pair.
  - User data for provisioning the database, including SQL seed data (`library.sql`).

### **3. Networking and Security**

- **Ingress and Egress Rules**:
  - For both the application and database instances, there are rules that define which ports and traffic types are allowed:
    - **SSH (Port 22)**: Access for secure shell login.
    - **HTTP (Port 5000)**: For communication between the application server and external users.
    - **MySQL (Port 3306)**: For communication between the application and database servers.
    - Egress rules allow all outbound traffic from both instances.

- **Security Group Dependencies**: The application server depends on the database instance for connectivity, with the database's private IP being passed into the application server's provisioning script.

### **4. Variables and Parameters**

- **User Data Scripts**:
  - The `prov-app.sh` script provisions the application server, while the `prov-db.sh` script provisions the database server. These scripts are expected to set up the necessary environments, such as installing Java and MySQL, as well as seeding the database with initial data.

---

## Application

### **App Provisioning Script**

[prov-app](prov-app.sh)

---

#### **1. Set the GitHub Repository URL**

```bash
# Set the GitHub repository URL as a variable
REPO_URL="https://PriyanSappal:${GITHUB_PAT}@github.com/PriyanSappal/java-spring-boot-app"
```

- **Purpose**: Initializes a variable `REPO_URL`, I have authenticated this with the PAT token as it is a private repo on GitHUB. PAT is in the `variable.tf` and not being pushed to GitHUB. 

---

#### **2. Package Update and Upgrade**

```bash
# Echo statement to indicate the start of the update and upgrade process
echo "[UPDATE & UPGRADE PACKAGES]"

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Upgrade all installed packages
echo "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
```

- **Purpose**:
  - Updates the list of available packages.
  - Upgrades all installed packages to their latest versions in a non-interactive mode, ensuring smooth automation.

---

#### **3. Install Java 17**

```bash
# Install Java 17
echo "Installing Java 17..."
sudo DEBIAN_FRONTEND=noninteractive apt install openjdk-17-jdk -y
```

- **Purpose**: Installs Java 17 JDK, which is required for running the Java-based application.

---

#### **4. Set Java Home Environment Variable**

```bash
# Set Java home environment variable and update the PATH
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
```

- **Purpose**:
  - Sets the `JAVA_HOME` environment variable to the installed Java 17 location.
  - Updates the system `PATH` to include the Java binaries so Java commands can be executed from any location.

---

#### **5. Install Maven**

```bash
# Install Maven by downloading and extracting the binary
echo "Downloading and installing Apache Maven..."
wget https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz

# Extract Maven to the /opt directory
echo "Extracting Maven to /opt directory..."
sudo tar -xvzf apache-maven-*.tar.gz -C /opt

# Move extracted Maven to a more appropriate directory
echo "Moving Maven to /opt/maven..."
sudo mv /opt/apache-maven-* /opt/maven
```

- **Purpose**:
  - Downloads the specified Apache Maven version.
  - Extracts the Maven binary archive to the `/opt` directory.
  - Moves the extracted Maven folder to a dedicated `/opt/maven` directory.

---

#### **6. Configure Maven Environment Variables**

```bash
# Export Maven environment variables
export M2_HOME=/opt/maven
export PATH=$M2_HOME/bin:$PATH
```

- **Purpose**:
  - Sets the `M2_HOME` environment variable to point to the Maven installation directory.
  - Updates the system `PATH` to include the Maven binaries, enabling the execution of Maven commands globally.

---


#### **7. Set Database Connection Variables**

```bash
# Export database connection details
export DB_USER="root"
export DB_PASS="password"
export DB_HOST=jdbc:mysql://${DATABASE_IP}:3306/library
```

- **Purpose**:
  - Sets the database user, password, and host as environment variables to be used later in the script.

---

#### **8. Clone the GitHub Repository**

```bash
# Clone the GitHub repository using the provided token for authentication
echo "Cloning the repository..."
git clone "$REPO_URL" repo
echo "Finished git clone"
```

- **Purpose**: Clones the specified GitHub repository using a GitHub token for authentication.

---

#### **9. Navigate to the Project Directory**

```bash
# Navigate into the cloned project directory
cd repo/LibraryProject2
```

- **Purpose**: Changes the current working directory to the project directory where the application is located.

---

#### **10. Wait for Database to Be Ready**

```bash
# Wait for a few seconds to ensure the database is ready
echo "Waiting for 5 seconds..."
sleep 5s
```

- **Purpose**: Pauses the script for 5 seconds to allow the database (or other services) to be fully initialized before proceeding.

---

#### **11. Build the Project**

```bash
# Build the project using Maven
echo "Building the project with Maven..."
mvn clean package
```

- **Purpose**: Uses Maven to clean the project and package it, preparing the application for deployment.

---

#### **12. Start the Spring Boot Application**

```bash
# Start the Spring Boot application
echo "Starting the Spring Boot application..."
mvn spring-boot:start
```

- **Purpose**: Uses Maven to start the Spring Boot application on the system. We use start here to allow the user data to finish. As when you have `mvn spring-boot:run` it runs in the foreground. 

---


### **Summary**

This script automates the process of:

1. Updating system packages.
2. Installing Java 17 and Maven.
3. Cloning a GitHub repository.
4. Building and starting a Spring Boot application using Maven.

It also provides helpful echo statements for tracking the progress of each step.

## Database

### **Database Provisioning Script**

[prov-db.sh](prov-db.sh): steps have been commented on the script below.

```bash
#!/bin/bash

# Exit immediately if a command exits with a non-zero status (uncomment if needed for strict error handling)
# set -e

# Variables
# Setting up the database name, user, and password (replace 'password' with a secure password for production)
DB_NAME="library"
DB_USER="root"
DB_PASS="password"

# Inform the user about the start of the system update process
echo "Updating system packages..."
# Set non-interactive mode to prevent prompts during updates
export DEBIAN_FRONTEND=noninteractive
# Update the package list
sudo apt update -y
# Upgrade all packages to their latest versions
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Inform the user about the installation of MySQL server
echo "Installing MySQL Server..."
# Install the MySQL server package in non-interactive mode
sudo DEBIAN_FRONTEND=noninteractive apt-get install mysql-server -y

# Start and enable MySQL service to ensure it runs on system boot
echo "Starting and enabling MySQL service..."
sudo systemctl start mysql
sudo systemctl enable mysql

# Configure the MySQL database and user
echo "Setting up MySQL database and user..."
# Create the database, user, and grant privileges; the `-ppassword` flag uses the root password
sudo mysql -ppassword -e "
CREATE DATABASE IF NOT EXISTS $DB_NAME; 
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS'; 
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'; 
FLUSH PRIVILEGES;"

# Download the database schema file from a GitHub repository
echo "Downloading library.sql file..."
# Use curl to fetch the file, providing a GitHub Personal Access Token (PAT) for authentication
curl -H "Authorization: token ${GITHUB_PAT}" -o library.sql https://raw.githubusercontent.com/PriyanSappal/java-spring-boot-app/refs/heads/main/library.sql?token=GHSAT0AAAAAACYJ4C47Y2DL7UBW7NRIXQAKZ2ELWSA
echo "Finished downloading library.sql file..."

# Seed the database with data from the downloaded file
echo "Seeding the database..."
# Use MySQL command-line tool to import the SQL file into the specified database
sudo mysql -u $DB_USER -p$DB_PASS $DB_NAME < library.sql
echo "Database seeded successfully."

# Configure MySQL for remote access
echo "Configuring MySQL for remote access..."
# Update MySQL configuration to allow connections from any IP address
sudo sed -i 's/\s*bind-address\s*=\s*127.0.0.1\s*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
# Restart MySQL to apply configuration changes
sudo systemctl restart mysql

# Final message to confirm setup completion and provide a security reminder
echo "MySQL Database VM setup is complete."
echo "Please ensure this VM's firewall allows access to MySQL on port 3306."
```

# Stage 4: Deploy the app and database on AWS or Azure using containers running on a Virtual Machine (Docker Compose). Automate it via Bash provision scripts that work in user data. (1-2 days).
## Pre-requisite information
- We will first run it locally.
    1) We will need to create a `.jar` file. This is done by `mvn clean package -DskipTests` - this essentially skips the tests for now as the way the app works it needs a connection with database to run so for now this will work fine.  
    2) We will need a `Dockerfile` and `docker-compose.yml` file where your app files are stored. 
- After this we will run this on an EC2 instance. 
    1) We will have one instance which we will provision using terraform. Within this we will make sure to first set up a provision script where we have no user data: [docker-provision.sh](docker/docker-provision.sh). We do this to test and see how we can automate our bash script fully. 
    2) After this we run it with user data. Terraform allows the infrastructure to be provisioned in seconds which makes testing the user data easier. Troubleshooting was made easier whne looking at the logs after `SSH` into the instance: `cat /var/log/cloud-init-output.log`

## Step 1: Using Dockerfile we first build an image. 
* [Dockerfile](docker/dockerfile) - this is commented. 
  * We have referenced a base image that will have all the necessary dependencies. 
  * Copied the `.jar` file. 
  * Exposed the port `5000`.
  * Finally we ran it. 
To execute this:
1) Build the image: `docker build -t priyansappal1/java-app:v1 .` *Common blocker: not including the `.`.*
2) We need to push this docker hub so we can access it later when we are deploying it using an EC2 instance: `docker push priyansappal1/java-app:v1`. 

## Step 2: Using `docker-compose.yml` to connect this with our MYSQL DB.
* We like to be in a habit to test things locally first, therefore we will take [docker-compose.yml](docker/docker-compose.yml) and compose our app. The script is commented to see what steps do what.
To execute this:
1) `docker compose up`: from this it will take the image we have created and depending on if the database is ready it will give us our frontpage and the `web/authors` page. 
2) `docker compose down -v`: this is to remove the containers. 

## Step 3: Launching an EC2 instance using terraform. 
* [Terraform Script with Docker Compose](docker/terraform/main.tf). This script is similar to the one used in **stage 3** but user data changes as we will need to reference our [docker-compose.yml](docker/docker-compose.yml).
  * In this we have allowed `SSH`, port `5000` as this is what our application is listening on and port `3306` for our DB connection.
To execute this:
1) `terrraform init`: to initialise the repo as a terraform repository.
2) `terraform plan`: this will plan out the changes that will happen (what will be provisioned).
3) `terraform apply`: this is a destructive command as it will actually make the EC2 instance with the NSG etc.
4) `terraform destroy`: this is a destructive command that will destroy the instances and everything else made. Used this when a mistake was made and used `terraform apply` to provision the infrastructure again. 
* After completing step 3: you will be able to see your desired results `http://<Public-IP>/web/authors`.

## Blockers
1) With the `docker-compose.yml`, the app container was building first and therefore was not connecting with the DB. The app needs to depend on the database. After adding this to the `database` service:
```yml
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 3
```
And adding this to the `app` service:
```yml
    depends_on:
      database:
        condition: service_healthy
```
The blocker was removed.
2) The database was not seeded. Added a step from the previous provision script written in **stage 3**:
```bash
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
```
This seeds the database. 
3) After **2)**, another blocker arose as the `docker compose up` command was running into errors which was that something was using the port `3306` and that was because the `mysql service` was still active. Used `sudo systemctl stop mysql.service` before running `docker compose up`. The service was running to seed the database. 
  


