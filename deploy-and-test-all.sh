#!/bin/bash
set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: config.env not found!${NC}"
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Scaling Cloud - Deploy and Test All Labs               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Function to wait for GitHub workflow
wait_for_workflow() {
    local workflow_name="$1"
    local timeout="$2"
    local interval=15
    
    print_info "Waiting for latest workflow run to complete..."
    sleep 10
    
    # Get the latest workflow run
    local run_id=$(gh run list --workflow="$workflow_name" --limit 1 --json databaseId --jq '.[0].databaseId')
    
    if [ -z "$run_id" ]; then
        print_error "Failed to get workflow run ID"
        return 1
    fi
    
    print_info "Monitoring workflow run: $run_id"
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        local status=$(gh run view "$run_id" --json status --jq '.status')
        local conclusion=$(gh run view "$run_id" --json conclusion --jq '.conclusion')
        
        if [ "$status" == "completed" ]; then
            if [ "$conclusion" == "success" ]; then
                print_success "Workflow completed successfully"
                return 0
            else
                print_error "Workflow failed with conclusion: $conclusion"
                gh run view "$run_id" --log-failed
                return 1
            fi
        fi
        
        print_info "Workflow status: $status (waiting ${elapsed}s/${timeout}s)"
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    print_error "Workflow timed out after ${timeout}s"
    return 1
}

# Check prerequisites
print_header "Checking Prerequisites"

command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed."; exit 1; }
command -v gh >/dev/null 2>&1 || { print_error "GitHub CLI is required but not installed."; exit 1; }

print_success "Azure CLI installed"
print_success "GitHub CLI installed"

# Check Azure login
if ! az account show >/dev/null 2>&1; then
    print_error "Not logged into Azure. Please run 'az login'"
    exit 1
fi
print_success "Logged into Azure"

# Check GitHub login
if ! gh auth status >/dev/null 2>&1; then
    print_error "Not logged into GitHub. Please run 'gh auth login'"
    exit 1
fi
print_success "Logged into GitHub"

# =============================================================================
# STEP 1: Ensure ACR image is available
# =============================================================================
print_header "Step 1: Checking Azure Container Registry Image"

print_info "Logging into ACR: $ACR_NAME..."
az acr login --name "$ACR_NAME" --resource-group "$RG_NAME" >/dev/null 2>&1
print_success "Logged into ACR"

# Check if image exists
if az acr repository show --name "$ACR_NAME" --repository my-website >/dev/null 2>&1; then
    print_success "Image 'my-website' already exists in ACR"
    TAGS=$(az acr repository show-tags --name "$ACR_NAME" --repository my-website --output tsv | tr '\n' ', ')
    print_info "Available tags: $TAGS"
else
    print_error "Image 'my-website' not found in ACR!"
    print_info "Please build and push the image first using the build workflow or manually"
    print_info "For manual push: cd lab1 && ./push-to-acr.sh"
    exit 1
fi

# =============================================================================
# STEP 2: Deploy Lab 3 (Container Apps)
# =============================================================================
print_header "Step 2: Deploying Lab 3 (Azure Container Apps)"

print_info "Triggering Lab 3 deployment via GitHub Actions..."
gh workflow run lab-bicep-deploy.yml -f labPath=lab3

if ! wait_for_workflow "lab-bicep-deploy.yml" 600; then
    print_error "Lab 3 deployment failed"
    exit 1
fi

# Verify Lab 3
LAB3_RG="rg-scalingcloud-lab3"
CONTAINER_APP_NAME=$(az containerapp list --resource-group "$LAB3_RG" --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$CONTAINER_APP_NAME" ]; then
    CONTAINER_APP_URL="https://$(az containerapp show --name "$CONTAINER_APP_NAME" --resource-group "$LAB3_RG" --query properties.configuration.ingress.fqdn -o tsv)"
    print_success "Lab 3 deployed successfully"
    print_info "Container App URL: $CONTAINER_APP_URL"
    
    # Test endpoint
    sleep 5
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTAINER_APP_URL")
    if [ "$HTTP_STATUS" == "200" ]; then
        print_success "Lab 3 endpoint test: PASSED (HTTP $HTTP_STATUS)"
    else
        print_error "Lab 3 endpoint test: FAILED (HTTP $HTTP_STATUS)"
    fi
else
    print_error "Lab 3 verification failed - Container App not found"
    exit 1
fi

# =============================================================================
# STEP 3: Deploy Lab 4 (Azure Front Door)
# =============================================================================
print_header "Step 3: Deploying Lab 4 (Azure Front Door)"

print_info "Triggering Lab 4 deployment via GitHub Actions..."
gh workflow run lab-bicep-deploy.yml -f labPath=lab4

if ! wait_for_workflow "lab-bicep-deploy.yml" 900; then
    print_error "Lab 4 deployment failed"
    exit 1
fi

# Verify Lab 4
LAB4_RG="rg-scalingcloud-lab4"
FRONTDOOR_PROFILE=$(az afd profile list --resource-group "$LAB4_RG" --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$FRONTDOOR_PROFILE" ]; then
    FRONTDOOR_ENDPOINT=$(az afd endpoint list --profile-name "$FRONTDOOR_PROFILE" --resource-group "$LAB4_RG" --query "[0].hostName" -o tsv)
    FRONTDOOR_URL="https://$FRONTDOOR_ENDPOINT"
    print_success "Lab 4 deployed successfully"
    print_info "Front Door URL: $FRONTDOOR_URL"
    
    # Wait for Front Door to propagate
    print_info "Waiting for Front Door to propagate (120s)..."
    sleep 120
    
    # Test endpoint
    MAX_RETRIES=5
    for i in $(seq 1 $MAX_RETRIES); do
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTDOOR_URL")
        if [ "$HTTP_STATUS" == "200" ]; then
            print_success "Lab 4 endpoint test: PASSED (HTTP $HTTP_STATUS)"
            break
        else
            if [ $i -eq $MAX_RETRIES ]; then
                print_error "Lab 4 endpoint test: FAILED (HTTP $HTTP_STATUS)"
            else
                print_info "Attempt $i/$MAX_RETRIES: HTTP $HTTP_STATUS, retrying..."
                sleep 15
            fi
        fi
    done
else
    print_error "Lab 4 verification failed - Front Door not found"
    exit 1
fi

# =============================================================================
# STEP 4: Deploy Lab 5 (Global Load Testing)
# =============================================================================
print_header "Step 4: Deploying Lab 5 (Global Load Testing)"

# Update lab5/lab.bicep with Front Door URL
cd "${SCRIPT_DIR}/lab5"
print_info "Updating lab5/lab.bicep with Front Door URL..."

# Backup original file
cp lab.bicep lab.bicep.backup

# Update the URL in the bicep file
sed -i.tmp "s|https://[a-zA-Z0-9.-]*azurefd.net|$FRONTDOOR_URL|g" lab.bicep
rm -f lab.bicep.tmp

# Check if file was modified
if git diff --quiet lab.bicep; then
    print_info "lab.bicep already has correct URL"
else
    print_info "Committing updated lab.bicep..."
    git add lab.bicep
    git commit -m "test: Update lab5 with Front Door URL for testing ($FRONTDOOR_URL)" || true
    git push || true
    print_success "lab.bicep updated and pushed"
fi

cd "${SCRIPT_DIR}"

print_info "Triggering Lab 5 deployment via GitHub Actions..."
gh workflow run lab-bicep-deploy.yml -f labPath=lab5

if ! wait_for_workflow "lab-bicep-deploy.yml" 600; then
    print_error "Lab 5 deployment failed"
    exit 1
fi

# Verify Lab 5
LAB5_RG="rg-scalingcloud-lab5"
CONTAINER_NAME=$(az container list --resource-group "$LAB5_RG" --query "[0].name" -o tsv 2>/dev/null)
if [ -n "$CONTAINER_NAME" ]; then
    print_success "Lab 5 deployed successfully"
    print_info "Container Instance: $CONTAINER_NAME"
    
    # Wait for container to complete
    print_info "Waiting for K6 container to complete (60s)..."
    sleep 60
    
    # Get logs
    print_info "K6 Load Test Results:"
    echo "----------------------------------------"
    az container logs --resource-group "$LAB5_RG" --name "$CONTAINER_NAME" || print_error "Failed to retrieve logs"
    echo "----------------------------------------"
else
    print_error "Lab 5 verification failed - Container Instance not found"
    exit 1
fi

# =============================================================================
# STEP 5: Run Comprehensive Tests
# =============================================================================
print_header "Step 5: Running Comprehensive Tests"

print_info "Running cloud lab tests..."
"${SCRIPT_DIR}/test/test-cloud-labs.sh"

# =============================================================================
# Final Summary
# =============================================================================
print_header "Deployment and Test Summary"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 ALL LABS DEPLOYED AND TESTED SUCCESSFULLY! 🎉        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "📊 Deployed Resources:"
echo ""
az group list --tag Project=scalingCloudLab --query "[].{Name:name, Location:location, Status:properties.provisioningState}" --output table
echo ""

print_info "🌐 Lab URLs:"
echo "  Lab 3 (Container Apps): $CONTAINER_APP_URL"
echo "  Lab 4 (Front Door):     $FRONTDOOR_URL"
echo ""

print_info "💰 Cost Notice: Azure resources are running and incurring costs."
print_info "🧹 To clean up all resources when done, run: ./infra/nuke.sh"
echo ""
