#!/bin/bash

# Variables
USERNAME="danielfroding"
REPOSITORY="my-website"
TAG="latest"

# Build the image
docker build --platform linux/amd64 -t $USERNAME/$REPOSITORY:$TAG .

# Log in to DockerHub
echo "Logging in to DockerHub..."
docker login

# Push the image
docker push $USERNAME/$REPOSITORY:$TAG

echo "Docker image pushed to DockerHub: $USERNAME/$REPOSITORY:$TAG"