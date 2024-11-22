# Local Deployment of a Java Spring Boot Application with MySQL

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
