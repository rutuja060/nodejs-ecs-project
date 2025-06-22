#!/bin/bash -xe

# Update packages and install Docker
sudo dnf update -y
sudo dnf install -y docker jq ruby wget

# Start Docker and enable it on boot
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Install SSM Agent (AL3 doesn't come with it by default)
sudo dnf install -y https://s3.${region}.amazonaws.com/amazon-ssm-${region}/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

# Install CodeDeploy agent
cd /home/ec2-user
wget https://aws-codedeploy-${region}.s3.${region}.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto -r ${region}
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent

# Create an environment file for CodeDeploy scripts to use
sudo bash -c 'cat > /etc/codedeploy-environment <<EOF
export REGION="${region}"
export SECRET_NAME="${secret_name}"
export ECR_REPO_NAME="${ecr_repo_name}"
export ACCOUNT_ID="${account_id}"
export DOCKER_IMAGE_TAG="${docker_image_tag}"
EOF'

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

# Stop any existing container
if sudo docker ps -q --filter "name=nodejs-app" | grep -q .; then
    sudo docker stop nodejs-app || true
    sudo docker rm nodejs-app || true
fi

# Pull and run Docker container
sudo docker pull ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_name}:${docker_image_tag}

sudo docker run -d --name nodejs-app \
  -e DB_USER=$DB_USER \
  -e DB_PASSWORD=$DB_PASSWORD \
  -e DB_HOST=$DB_HOST \
  -e DB_NAME=$DB_NAME \
  -e DB_PORT=$DB_PORT \
  -p 3000:3000 \
  ${account_id}.dkr.ecr.${region}.amazonaws.com/${ecr_repo_name}:${docker_image_tag}

