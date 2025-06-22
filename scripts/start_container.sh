#!/bin/bash
set -e

# This file will be created by the CI/CD pipeline and included in the S3 bundle
IMAGE_TAG_FILE="/home/ec2-user/app/image-tag.txt"
if [ ! -f "$IMAGE_TAG_FILE" ]; then
    echo "Image tag file not found at $IMAGE_TAG_FILE"
    exit 1
fi
IMAGE_TAG=$(cat "$IMAGE_TAG_FILE")

# Source environment variables created by user_data
echo "--> Checking for environment file..."
if [ -f /etc/codedeploy-environment ]; then
  echo "--> Sourcing /etc/codedeploy-environment..."
  cat /etc/codedeploy-environment # Print file content for debugging
  . /etc/codedeploy-environment
else
  echo "--> ERROR: /etc/codedeploy-environment file not found!"
  exit 1
fi

# ---
# Validate that essential variables are set
# ---
echo "--> Validating environment variables..."
if [ -z "${REGION}" ] || [ -z "${ACCOUNT_ID}" ] || [ -z "${ECR_REPO_NAME}" ]; then
    echo "--> ERROR: One or more required environment variables (REGION, ACCOUNT_ID, ECR_REPO_NAME) are not set."
    echo "    REGION: ${REGION}"
    echo "    ACCOUNT_ID: ${ACCOUNT_ID}"
    echo "    ECR_REPO_NAME: ${ECR_REPO_NAME}"
    exit 1
fi
echo "--> Variables are set. REGION is ${REGION}."


# Log in to Amazon ECR
aws ecr get-login-password --region ${REGION} | sudo docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Pull the Docker image from ECR
sudo docker pull ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}

# Fetch secrets
SECRETS=$(aws secretsmanager get-secret-value --secret-id ${SECRET_NAME} --region ${REGION} --query SecretString --output text)
DB_USER=$(echo "$SECRETS" | jq -r .username)
DB_PASSWORD=$(echo "$SECRETS" | jq -r .password)
DB_HOST=$(echo "$SECRETS" | jq -r .host)
DB_NAME=$(echo "$SECRETS" | jq -r .dbname)
DB_PORT=$(echo "$SECRETS" | jq -r .port)

# Run the Docker container
sudo docker run -d --name nodejs-app \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASSWORD \
  -e DB_HOST=$DB_HOST \
  -e DB_NAME=$DB_NAME \
  -e DB_PORT=$DB_PORT \
  -p 3000:3000 \
  "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO_NAME}:${IMAGE_TAG}" 