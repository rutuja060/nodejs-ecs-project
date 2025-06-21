#!/bin/bash -xe

# Update packages and install Docker
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Install jq to easily parse JSON from Secrets Manager
yum install -y jq

# Use the EC2 instance's IAM role to log in to ECR
aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${ecr_repo_url}

# Fetch the database credentials from Secrets Manager
secrets=$(aws secretsmanager get-secret-value --secret-id ${secret_name} --region ${region} --query SecretString --output text)

# Parse the secrets and export them as environment variables
# Note: The keys (.username, .password) must match what you stored in Secrets Manager
DB_USER=$(echo "$secrets" | jq -r .username)
DB_PASSWORD=$(echo "$secrets" | jq -r .password)
DB_HOST=$(echo "$secrets" | jq -r .host)
DB_NAME=$(echo "$secrets" | jq -r .dbname)
DB_PORT=$(echo "$secrets" | jq -r .port)

# Pull Docker image with version
docker pull ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_url}:${docker_image_tag}

# Run Docker container with environment variables
docker run -d \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASSWORD \
  -e DB_NAME=$DB_NAME \
  -e DB_HOST=$DB_HOST \
  -p 3000:3000 \
  ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_url}:${docker_image_tag}