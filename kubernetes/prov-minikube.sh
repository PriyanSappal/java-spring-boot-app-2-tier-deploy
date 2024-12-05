#!/bin/bash
# 1. Provision Docker
# 2. Provision minikube
# 3. minikube addons
# 4. Provision nginx to expose the required NodePort when going to the public IP of the instance


echo "Installing minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64

echo "Setting driver to Docker"
minikube config set driver docker

echo "Minikube is configured to use Docker as the driver."

 
echo "UPDATE & UPGRADE PACKAGES" 
# Update packages
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# DOCKER
# Add Docker's official GPG key:
echo "Adding Dockers GPG key"
# Install docker
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo "Adding repository to Apt sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

echo "[PROVISIONING DOCKER]: Installing Docker"
sudo DEBIAN_FRONTEND=noninteractive apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
echo "[PROVISIONING DOCKER]: Complete\n"

# Check if the user is already part of the docker group
if ! groups ubuntu | grep -q '\bdocker\b'; then
    echo "[PROVISIONING MINIKUBE]: Adding ubuntu to the docker group..."
    sudo usermod -aG docker ubuntu

    echo "[PROVISIONING MINIKUBE]: Restarting script to apply Docker group permissions..."
    exec sg docker "$0"
    exit
fi
# MINIKUBE

# Install minikube
echo "[PROVISIONING MINIKUBE]: Downloading minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

echo "[PROVISIONING MINIKUBE]: Installing minikube..."
sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64


#echo "[PROVISIONING MINIKUBE]: Creating user group named 'docker'"


# CLONING APP-DEPLOYMENT

mkdir /home/ubuntu/app

sudo tee /home/ubuntu/app/app-deploy.yml <<EOF
---
# db-persistent-volume-claim.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-db-pvc
  labels:
    type: local
spec:
  volumeName: app-db-pv
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Mi

---
# db-persistent-volume.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-db-pv
  labels:
    type: local
spec:
  claimRef:
    namespace: default
    name: app-db-pvc
  storageClassName: manual
  capacity:
    storage: 100Mi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /var/lib/mysql


---
# DB DEPLOYMENT
apiVersion: apps/v1  # specify api to use for deployment
kind : Deployment  # kind of service/object you want to create
metadata:
  name: db-deployment 
spec:
  selector:
    matchLabels:
      app: java-app-db # look for this labe/tag to match the k8n service

  # Create a ReplicaSet with instances/pods
  replicas: 1
  template:
    metadata:
      labels:
        app: java-app-db
    spec:
      containers:
      - name: java-app-db
        image: mysql
        env:
          - name: MYSQL_ROOT_PASSWORD
            value: root
          - name: MYSQL_DATABASE
            value: library
        ports:
        - containerPort: 3306
        volumeMounts:
          - name: db-storage
            mountPath: /var/lib/mysql
          - name: init-script
            mountPath: /docker-entrypoint-initdb.d/library.sql
            subPath: library.sql

      volumes:
      - name: db-storage
        persistentVolumeClaim:
          claimName: app-db-pvc
      - name: init-script
        configMap:
          name: library-sql-configmap

---
apiVersion: v1
kind: Service
metadata:
  name: java-app-db-svc
  namespace: default
spec:
  ports:
  - protocol: TCP
    port: 3306
    targetPort: 3306
  selector:
    app: java-app-db  # Label to match service to deployment
  type: ClusterIP

---
# APP DEPLOYMENT
apiVersion: apps/v1  # specify api to use for deployment
kind : Deployment  # kind of service/object you want to create
metadata:
  name: app-deployment 
spec:
  selector:
    matchLabels:
      app: java-app # look for this labe/tag to match the k8n service

  # Creaate a ReplicaSet with instances/pods
  replicas: 1
  template:
    metadata:
      labels:
        app: java-app
    spec:
      initContainers:
      - name: wait-for-db
        image: busybox
        command:
          - sh
          - -c
          - >
            until nc -z java-app-db-svc 3306; do
              echo "Waiting for database...";
              sleep 5;
            done;
      containers:
      - name: java-app
        image: priyansappal1/java-app:v1
        ports:
        - containerPort: 5000
        env:
          - name: DB_HOST
            value: jdbc:mysql://java-app-db-svc:3306/library
          - name: DB_USER
            value: root
          - name: DB_PASS
            value: root
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"   # Optional CPU limit

---

apiVersion: v1
kind: Service
metadata:
  name: java-app-svc
  namespace: default
spec:
  ports:
  - nodePort: 30001
    port: 5000
    targetPort: 5000
  selector:
    app: java-app  # Label to match service to deployment
  type: NodePort

---
# apiVersion: autoscaling/v2
# kind: HorizontalPodAutoscaler
# metadata:
#   name: app-hpa
# spec:
#   scaleTargetRef:
#     apiVersion: apps/v1
#     kind: Deployment
#     name: app-deployment
#   minReplicas: 2
#   maxReplicas: 3
#   metrics:
#   - type: Resource
#     resource:
#       name: cpu
#       target:
#         type: Utilization
#         averageUtilization: 75


---
# ConfigMap for Initial SQL Script
apiVersion: v1
kind: ConfigMap
metadata:
  name: library-sql-configmap
data:
  library.sql: |
    DROP DATABASE IF EXISTS library;
    CREATE DATABASE library;
    USE library;

    CREATE TABLE authors (
    author_id int PRIMARY KEY NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(40)
    );
    CREATE TABLE books (
    book_id int  PRIMARY KEY NOT NULL AUTO_INCREMENT,
    title VARCHAR(100),
    author_id int,
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
    );

    INSERT INTO library.authors (full_name) VALUES ('Phil');
    INSERT INTO library.authors (full_name) VALUES ('William Shakespeare');
    INSERT INTO library.authors (full_name) VALUES ('Jane Austen');
    INSERT INTO library.authors (full_name) VALUES ('Charlees Dickeens');
EOF


sudo tee /home/ubuntu/app/library.sql <<EOF
DROP DATABASE IF EXISTS library;
CREATE DATABASE library;
USE library;

CREATE TABLE authors (
author_id int PRIMARY KEY NOT NULL AUTO_INCREMENT,
full_name VARCHAR(40)
);
CREATE TABLE books (
book_id int  PRIMARY KEY NOT NULL AUTO_INCREMENT,
title VARCHAR(100),
author_id int,
FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

INSERT INTO library.authors (full_name) VALUES ('Phil');
INSERT INTO library.authors (full_name) VALUES ('William Shakespeare');
INSERT INTO library.authors (full_name) VALUES ('Jane Austen');
INSERT INTO library.authors (full_name) VALUES ('Charlees Dickeens');
EOF



echo "Running as $(whoami)"
# Run Minikube as 'ubuntu' user after Docker group is applied
sudo -u ubuntu -i bash <<'EOF'

echo "[PROVISIONING MINIKUBE]: Starting Minikube as 'ubuntu' user..."
echo "Running as $(whoami)"

# Running Minikube as the 'ubuntu' user to ensure it uses Docker
minikube start

minikube status
echo "[PROVISIONING MINIKUBE]: Exporting Minikube IP"
MINIKUBE_IP=$(minikube ip)
echo "[PROVISIONING MINIKUBE]: Exported Minikube IP: $MINIKUBE_IP"
echo "[PROVISIONING MINIKUBE]: Complete"
echo

# NGINX
echo "[PROVISIONING NGINX]: Installing..."
# Install Nginx
echo "Installing Nginx..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install nginx -y
echo "Done!"

echo "[PROVISIONING NGINX]: Setting reverse proxy to $MINIKUBE_IP:30001"
# Use sed to update the proxy settings in the configuration file
sudo sed -i "s|try_files \$uri \$uri/ =404;|proxy_pass http://$MINIKUBE_IP:30001;|" /etc/nginx/sites-available/default

# Check syntax error
sudo nginx -t

# Restart Nginx
echo "[PROVISIONING NGINX]: Restarting..."
sudo systemctl restart nginx
echo "[PROVISIONING NGINX]: Complete"
EOF


sudo -u ubuntu -i bash <<'EOF'
cd /home/ubuntu/app

#!/bin/bash

minikube kubectl -- apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

minikube kubectl -- patch deployment metrics-server -n kube-system --type='json' -p='[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--kubelet-insecure-tls"
  }
]'

minikube kubectl -- rollout restart deployment metrics-server -n kube-system

minikube kubectl -- apply -f app-deploy.yml

minikube kubectl -- get all

EOF




