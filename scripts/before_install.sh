#!/bin/bash
set -e

echo "Starting BeforeInstall hook..."

# Stop any existing containers
if sudo docker ps -q --filter "name=nodejs-app" | grep -q .; then
    echo "Stopping existing nodejs-app container..."
    sudo docker stop nodejs-app || true
    sudo docker rm nodejs-app || true
fi

# Remove any dangling images to free up space
echo "Cleaning up Docker images..."
sudo docker image prune -f || true

# Ensure Docker is running
echo "Ensuring Docker service is running..."
sudo systemctl start docker || true
sudo systemctl enable docker || true

# Create app directory if it doesn't exist
sudo mkdir -p /home/ec2-user/app
sudo chown ec2-user:ec2-user /home/ec2-user/app

echo "BeforeInstall hook completed successfully." 