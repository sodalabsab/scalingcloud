#!/bin/bash

# 1. Initialize Git Repository (if not already)
git init -b main
git add .
git commit -m "Initial commit of Azure Container Apps demo"

# 2. Create GitHub Repository
# Change 'public' to 'private' if desired
gh repo create aca-demo --public --source=. --remote=origin --push

# 3. Set GitHub Secrets
echo "Setting GitHub Secrets..."

RESOURCE_GROUP="rg-aca-platform"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "Generating Azure Service Principal for GitHub Actions..."
# Create a Service Principal with Contributor access to the specific Resource Group
# This forces a reset of the credentials to ensure they are valid
AZURE_CREDENTIALS=$(az ad sp create-for-rbac --name "aca-demo-lab-sp" --role contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP" \
  --sdk-auth \
  --output json)
echo "✓ Service Principal created."

echo "Setting GitHub Secrets..."
gh secret set AZURE_CREDENTIALS --body "$AZURE_CREDENTIALS"

# Fetch and set other secrets
echo "Fetching Platform details from Azure..."
ACR_NAME=$(az acr list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
ENVIRONMENT_ID=$(az containerapp env list --resource-group $RESOURCE_GROUP --query "[0].id" -o tsv)

echo "Setting ACR_NAME: $ACR_NAME"
gh secret set ACR_NAME --body "$ACR_NAME"

echo "Setting ACA_ENVIRONMENT_ID..."
gh secret set ACA_ENVIRONMENT_ID --body "$ENVIRONMENT_ID"

echo "Setting RESOURCE_GROUP..."
gh secret set RESOURCE_GROUP --body "$RESOURCE_GROUP"

echo "✅ Repository created and secrets configured!"
echo "Check your Actions tab in GitHub to see the deployment running."
