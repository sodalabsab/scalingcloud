#!/bin/bash

# Variables
ACR_NAME="<your-acr-name>"
REPOSITORY="my-website"
TAG="latest"

# Build the image
docker build --platform linux/amd64 -t $ACR_NAME.azurecr.io/$REPOSITORY:$TAG .

# Log in to ACR
echo "Logging in to Azure Container Registry..."
az acr login --name $ACR_NAME

# Push the image
docker push $ACR_NAME.azurecr.io/$REPOSITORY:$TAG

echo "Docker image pushed to ACR: $ACR_NAME.azurecr.io/$REPOSITORY:$TAG"