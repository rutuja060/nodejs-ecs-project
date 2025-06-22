#!/bin/bash
set -e

echo "Starting ValidateService hook..."

# Wait for the application to start
echo "Waiting for application to start..."
sleep 30

# Check if container is running
if ! sudo docker ps --format "table {{.Names}}" | grep -q "nodejs-app"; then
    echo "ERROR: Container nodejs-app is not running!"
    exit 1
fi

echo "Container is running. Checking application health..."

# Get the container's IP address
CONTAINER_IP=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nodejs-app)

# Test the health endpoint
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1)): Testing health endpoint..."
    
    # Try to curl the health endpoint
    if curl -f -s http://localhost:3000/health > /dev/null 2>&1; then
        echo "SUCCESS: Application is responding to health checks!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "Health check failed. Retrying in 10 seconds..."
        sleep 10
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: Application failed to respond to health checks after $MAX_RETRIES attempts!"
    echo "Container logs:"
    sudo docker logs nodejs-app
    exit 1
fi

# Additional validation - check if the application is listening on port 3000
if ! sudo netstat -tlnp | grep -q ":3000"; then
    echo "ERROR: Application is not listening on port 3000!"
    exit 1
fi

echo "ValidateService hook completed successfully." 