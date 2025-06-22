#!/bin/bash
set -e

CONTAINER_NAME="nodejs-app"

# Check if a container with the specified name is running and stop/remove it
if [ "$(sudo docker ps -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Stopping container ${CONTAINER_NAME}"
    sudo docker stop ${CONTAINER_NAME}
fi

if [ "$(sudo docker ps -aq -f status=exited -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Removing container ${CONTAINER_NAME}"
    sudo docker rm ${CONTAINER_NAME}
fi 