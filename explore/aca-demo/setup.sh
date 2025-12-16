#!/bin/bash
set -e

# Configuration
LOCATION="swedencentral"
SUBSCRIPTION_SCOPE_FILE="infra/platform/main.bicep"

echo "🚀 Starting Platform Setup..."

# Deploy Platform Infrastructure (Resource Group, ACR, ACA Environment)
echo "📦 Deploying Platform Infrastructure (this may take a few minutes)..."
OUTPUT=$(az deployment sub create \
  --name "aca-platform-setup-$(date +%s)" \
  --location "$LOCATION" \
  --template-file "$SUBSCRIPTION_SCOPE_FILE" \
  --query "properties.outputs" \
  --output json)

# Parse Outputs
ACR_NAME=$(echo "$OUTPUT" | jq -r .acrName.value)
ACR_LOGIN_SERVER=$(echo "$OUTPUT" | jq -r .acrLoginServer.value)
ENVIRONMENT_ID=$(echo "$OUTPUT" | jq -r .environmentId.value)

echo "✅ Platform Setup Complete!"
echo "--------------------------------------------------"
echo "PLEASE CONFIGURE THESE SECRETS IN YOUR GITHUB REPO:"
echo "--------------------------------------------------"
echo "ACR_NAME:        $ACR_NAME"
echo "ACR_LOGIN_SERVER:$ACR_LOGIN_SERVER"
echo "aca_environment_id:$ENVIRONMENT_ID"
echo "RESOURCE_GROUP:  rg-aca-platform"
echo "--------------------------------------------------"
