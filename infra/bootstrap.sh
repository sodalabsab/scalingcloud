#!/bin/bash
set -e # Stop execution instantly if any command fails

# --- 🔍 Pre-flight Checks -------------------------------------------------
echo "🔍 Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo "❌ Error: Azure CLI ('az') is not installed."
    exit 1
fi

if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI ('gh') is not installed."
    exit 1
fi

if ! az account show &> /dev/null; then
    echo "❌ Error: You are not logged into Azure. Run 'az login'."
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Error: You are not logged into GitHub. Run 'gh auth login'."
    exit 1
fi

echo "✅ Prerequisites OK!"
echo ""

# --- ⚙️ Load Configuration ------------------------------------------------
if [ -f "./config.env" ]; then
    source ./config.env
    echo "✅ Configuration loaded from config.env"
else
    echo "❌ Error: config.env file not found!"
    exit 1
fi

echo "🚀 Starting Bootstrap for Repo: $GH_ORG/$GH_REPO..."

# --- 🏗️ Main Logic --------------------------------------------------------

# 1. Create Resource Group
echo "--- 📦 Creating Resource Group: $RG_NAME ---"
az group create --name "$RG_NAME" --location "$LOCATION" --output none

# 2. Set up the 'Infra' Identity (The Pipeline Runner)
echo "--- 🛡️ Setting up Infra Identity: $INFRA_ID_NAME ---"
az identity create --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --output none
INFRA_PRINCIPAL_ID=$(az identity show --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --query principalId -o tsv)
INFRA_CLIENT_ID=$(az identity show --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --query clientId -o tsv)

echo "   ...Waiting 20 seconds for Identity propagation..."
sleep 20

# 3. Grant 'Owner' to Infra Identity
echo "--- 🔑 Assigning 'Owner' Role to Infra Identity ---"
SUB_ID=$(az account show --query id -o tsv)
az role assignment create \
  --assignee "$INFRA_PRINCIPAL_ID" \
  --role "Owner" \
  --scope "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" \
  --output none

# 4. Federate Infra Identity with GitHub (OIDC)
echo "--- 🤝 Federating Infra Identity with GitHub ---"
az identity federated-credential create \
  --name "github-infra-fed" \
  --identity-name "$INFRA_ID_NAME" \
  --resource-group "$RG_NAME" \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:$GH_ORG/$GH_REPO:ref:refs/heads/$GH_BRANCH" \
  --audiences "api://AzureADTokenExchange" \
  --output none || echo "   (Federation might already exist, continuing...)"

# 5. Set Common GitHub Secrets
echo "--- 🔒 Setting Global GitHub Secrets ---"
TENANT_ID=$(az account show --query tenantId -o tsv)
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUB_ID" --repo "$GH_ORG/$GH_REPO"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo "$GH_ORG/$GH_REPO"

# 6. Set Infra Pipeline Secret
echo "--- 🔒 Setting Infra Pipeline Secret (AZURE_CLIENT_ID_INFRA) ---"
gh secret set AZURE_CLIENT_ID_INFRA --body "$INFRA_CLIENT_ID" --repo "$GH_ORG/$GH_REPO"

# 7. Initial Bicep Deployment
echo "--- 🏗️ Running Initial Bicep Deployment ---"
if [ ! -f "main.bicep" ]; then
    echo "❌ Error: main.bicep file not found!"
    exit 1
fi

# Pass all variables from config.env into Bicep parameters
az deployment group create \
  --resource-group "$RG_NAME" \
  --template-file main.bicep \
  --parameters \
    githubUser="$GH_ORG" \
    githubRepo="$GH_REPO" \
    acrName="$ACR_NAME" \
    acrSku="$ACR_SKU" \
    identityNamePull="$APP_PULL_ID" \
    identityNamePush="$APP_PUSH_ID" \
    environmentName="$ENV_NAME" \
    containerImage="mcr.microsoft.com/k8se/quickstart:latest" \
  --output none

# 8. Fetch App Identity Details (Created by Bicep)
echo "--- 🔍 Fetching App Push Identity Details ---"
# We look up the Push ID because that is what the App Pipeline needs to login
APP_PUSH_CLIENT_ID=$(az identity show --name "$APP_PUSH_ID" --resource-group "$RG_NAME" --query clientId -o tsv)

# 9. Set App Pipeline Secret
echo "--- 🔒 Setting App Pipeline Secret (AZURE_CLIENT_ID) ---"
gh secret set AZURE_CLIENT_ID --body "$APP_PUSH_CLIENT_ID" --repo "$GH_ORG/$GH_REPO"

echo "--- 💾 Saving config.env values to GitHub Secrets ---"
# These allow infra.yml to know your specific naming choices
gh variable set RG_NAME --body "$RG_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set LOCATION --body "$LOCATION" --repo "$GH_ORG/$GH_REPO"
gh variable set ACR_NAME --body "$ACR_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set ACR_SKU --body "$ACR_SKU" --repo "$GH_ORG/$GH_REPO"
gh variable set ENV_NAME --body "$ENV_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set APP_PULL_ID --body "$APP_PULL_ID" --repo "$GH_ORG/$GH_REPO"
gh variable set APP_PUSH_ID --body "$APP_PUSH_ID" --repo "$GH_ORG/$GH_REPO"

echo ""
echo "✅ Bootstrap Complete!"
echo "   Resource Group: $RG_NAME"
echo "   Registry:       $ACR_NAME ($ACR_SKU)"
echo "   GitHub Repo:    $GH_ORG/$GH_REPO"
echo "   Secrets Pushed: AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, AZURE_CLIENT_ID_INFRA, AZURE_CLIENT_ID"