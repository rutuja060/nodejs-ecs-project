#!/bin/bash
set -e

echo "Starting AfterInstall hook..."

# Set proper permissions for the application files
echo "Setting application permissions..."
sudo chown -R ec2-user:ec2-user /home/ec2-user/app
sudo chmod -R 755 /home/ec2-user/app

# Make scripts executable
echo "Making scripts executable..."
sudo chmod +x /home/ec2-user/app/scripts/*.sh

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
fi

# Install jq for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "Installing jq..."
    sudo yum install -y jq
fi

echo "AfterInstall hook completed successfully." 