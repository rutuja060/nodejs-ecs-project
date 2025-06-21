#!/bin/bash -xe

# Update packages and install Docker
dnf update -y
dnf install -y docker jq unzip curl

# Start Docker and enable it on boot
systemctl enable docker
systemctl start docker
usermod -a -G docker ec2-user

# Install SSM Agent (AL3 doesn't come with it by default)
dnf install -y https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Log in to ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${region}.amazonaws.com

# Fetch secrets from AWS Secrets Manager
secrets=$(aws secretsmanager get-secret-value --secret-id ${secret_name} --region ${region} --query SecretString --output text)

# Extract DB credentials from secrets
DB_USER=$(echo "$secrets" | jq -r .username)
DB_PASSWORD=$(echo "$secrets" | jq -r .password)
DB_HOST=$(echo "$secrets" | jq -r .host)
DB_NAME=$(echo "$secrets" | jq -r .dbname)
DB_PORT=$(echo "$secrets" | jq -r .port)

# Pull and run Docker container
docker pull ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_url}:${docker_image_tag}

docker run -d \
  -e POSTGRES_USER=$DB_USER \
  -e POSTGRES_PASSWORD=$DB_PASSWORD \
  -e POSTGRES_HOST=$DB_HOST \
  -e POSTGRES_DB=$DB_NAME \
  -e POSTGRES_PORT=$DB_PORT \
  -p 3000:3000 \
  ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_url}:${docker_image_tag}

# Logging
sleep 10
docker ps > /var/log/docker_ps.log
docker logs $(docker ps -q) > /var/log/app_logs.log
