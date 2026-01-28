$ErrorActionPreference = "Stop"

# --- 🔍 Pre-flight Checks -------------------------------------------------
Write-Host "🔍 Checking prerequisites..."

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Azure CLI ('az') is not installed."
    exit 1
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: GitHub CLI ('gh') is not installed."
    exit 1
}

try {
    az account show | Out-Null
} catch {
    Write-Host "❌ Error: You are not logged into Azure. Run 'az login'."
    exit 1
}

try {
    gh auth status | Out-Null
} catch {
    Write-Host "❌ Error: You are not logged into GitHub. Run 'gh auth login'."
    exit 1
}

Write-Host "✅ Prerequisites OK!"
Write-Host ""

# --- ⚙️ Load Configuration ------------------------------------------------
if (Test-Path "../config.env") {
    Get-Content "../config.env" | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
    Write-Host "✅ Configuration loaded from ../config.env"
} else {
    Write-Host "❌ Error: config.env file not found in root directory!"
    exit 1
}

# --- ⚡ Set Defaults (Simplicity Update) -----------------------------------
$ACR_SKU = if ([string]::IsNullOrWhiteSpace($env:ACR_SKU)) { "Basic" } else { $env:ACR_SKU }
$ENV_NAME = if ([string]::IsNullOrWhiteSpace($env:ENV_NAME)) { "appEnvironment" } else { $env:ENV_NAME }

$INFRA_ID_NAME = "id-github-infra"
$APP_PULL_ID = "id-app-pull"
$APP_PUSH_ID = "id-github-push"

$GH_ORG = $env:GH_ORG
$GH_REPO = $env:GH_REPO
$RG_NAME = $env:RG_NAME
$LOCATION = $env:LOCATION
$GH_BRANCH = $env:GH_BRANCH
$ACR_NAME = $env:ACR_NAME

Write-Host "🚀 Starting Cloud Setup for Repo: $GH_ORG/$GH_REPO..."

# --- 🏗️ Main Logic --------------------------------------------------------

# 1. Create Resource Group
Write-Host "--- 📦 Creating Resource Group: $RG_NAME ---"
az group create --name "$RG_NAME" --location "$LOCATION" --output none

# Register Resource Providers
az provider register --namespace Microsoft.ContainerInstance
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.ContainerRegistry
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.ManagedIdentity

# 2. Set up the 'Infra' Identity (The Pipeline Runner)
Write-Host "--- 🛡️ Setting up Infra Identity: $INFRA_ID_NAME ---"
az identity create --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --output none
$INFRA_PRINCIPAL_ID = (az identity show --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --query principalId -o tsv)
$INFRA_CLIENT_ID = (az identity show --name "$INFRA_ID_NAME" --resource-group "$RG_NAME" --query clientId -o tsv)

Write-Host "   ...Waiting 20 seconds for Identity propagation..."
Start-Sleep -Seconds 20

# 3. Grant 'Owner' to Infra Identity
Write-Host "--- 🔑 Assigning 'Owner' Role to Infra Identity ---"
$SUB_ID = (az account show --query id -o tsv)
az role assignment create `
  --assignee "$INFRA_PRINCIPAL_ID" `
  --role "Owner" `
  --scope "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" `
  --output none

# 4. Federate Infra Identity with GitHub (OIDC)
Write-Host "--- 🤝 Federating Infra Identity with GitHub ---"
try {
    az identity federated-credential create `
      --name "github-infra-fed" `
      --identity-name "$INFRA_ID_NAME" `
      --resource-group "$RG_NAME" `
      --issuer "https://token.actions.githubusercontent.com" `
      --subject "repo:$GH_ORG/${GH_REPO}:ref:refs/heads/$GH_BRANCH" `
      --audiences "api://AzureADTokenExchange" `
      --output none
} catch {
    Write-Host "   (Federation might already exist or failed, continuing...)"
}

# 5. Set Common GitHub Secrets
Write-Host "--- 🔒 Setting Global GitHub Secrets ---"
$TENANT_ID = (az account show --query tenantId -o tsv)
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUB_ID" --repo "$GH_ORG/$GH_REPO"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID" --repo "$GH_ORG/$GH_REPO"

# 6. Set Infra Pipeline Secret
Write-Host "--- 🔒 Setting Infra Pipeline Secret (AZURE_CLIENT_ID_INFRA) ---"
gh secret set AZURE_CLIENT_ID_INFRA --body "$INFRA_CLIENT_ID" --repo "$GH_ORG/$GH_REPO"

# 7. Initial Bicep Deployment
Write-Host "--- 🏗️ Running Initial Bicep Deployment ---"
if (-not (Test-Path "main.bicep")) {
    Write-Host "❌ Error: main.bicep file not found!"
    exit 1
}

# Pass all variables from config.env into Bicep parameters
az deployment group create `
  --resource-group "$RG_NAME" `
  --template-file main.bicep `
  --parameters `
    githubUser="$GH_ORG" `
    githubRepo="$GH_REPO" `
    acrName="$ACR_NAME" `
    containerImage="mcr.microsoft.com/k8se/quickstart:latest" `
  --output none

# 8. Fetch App Identity Details (Created by Bicep)
Write-Host "--- 🔍 Fetching App Push Identity Details ---"
# We look up the Push ID because that is what the App Pipeline needs to login
$APP_PUSH_CLIENT_ID = (az identity show --name "$APP_PUSH_ID" --resource-group "$RG_NAME" --query clientId -o tsv)

# 9. Set App Pipeline Secret
Write-Host "--- 🔒 Setting App Pipeline Secret (AZURE_CLIENT_ID) ---"
gh secret set AZURE_CLIENT_ID --body "$APP_PUSH_CLIENT_ID" --repo "$GH_ORG/$GH_REPO"

Write-Host "--- 💾 Saving config.env values to GitHub Secrets ---"
# These allow infra.yml to know your specific naming choices
gh variable set RG_NAME --body "$RG_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set LOCATION --body "$LOCATION" --repo "$GH_ORG/$GH_REPO"
gh variable set ACR_NAME --body "$ACR_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set ACR_SKU --body "$ACR_SKU" --repo "$GH_ORG/$GH_REPO"
gh variable set ENV_NAME --body "$ENV_NAME" --repo "$GH_ORG/$GH_REPO"
gh variable set APP_PULL_ID --body "$APP_PULL_ID" --repo "$GH_ORG/$GH_REPO"
gh variable set APP_PUSH_ID --body "$APP_PUSH_ID" --repo "$GH_ORG/$GH_REPO"

Write-Host ""
Write-Host "✅ Cloud Setup Complete!"
Write-Host "   Resource Group: $RG_NAME"
Write-Host "   Registry:       $ACR_NAME ($ACR_SKU)"
Write-Host "   GitHub Repo:    $GH_ORG/$GH_REPO"
Write-Host "   Secrets Pushed: AZURE_SUBSCRIPTION_ID, AZURE_TENANT_ID, AZURE_CLIENT_ID_INFRA, AZURE_CLIENT_ID"
