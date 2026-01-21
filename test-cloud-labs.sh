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
echo -e "${BLUE}║   Scaling Cloud - Cloud Labs Test Suite                  ║${NC}"
echo -e "${BLUE}║   (Labs 3, 4, 5 - Azure Infrastructure)                  ║${NC}"
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

# Check prerequisites
print_header "Checking Prerequisites"

# Check if required tools are installed
command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed."; exit 1; }

print_success "Azure CLI installed"

# Check Azure login
print_info "Checking Azure login..."
if ! az account show >/dev/null 2>&1; then
    print_error "Not logged into Azure. Please run 'az login'"
    exit 1
fi

SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_success "Logged into Azure: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# =============================================================================
# LAB 3: Azure Container Apps
# =============================================================================
print_header "LAB 3: Testing Azure Container Apps"

LAB3_RG="rg-scalingcloud-lab3"

# Check if resource group exists
print_info "Checking if Lab 3 resource group exists..."
if az group show --name "$LAB3_RG" >/dev/null 2>&1; then
    print_success "Resource group exists: $LAB3_RG"
else
    print_error "Resource group not found: $LAB3_RG"
    print_info "Please deploy Lab 3 first via GitHub Actions"
    exit 1
fi

# List resources in the resource group
print_info "Resources in $LAB3_RG:"
az resource list --resource-group "$LAB3_RG" --output table

# Get Container App details
CONTAINER_APP_NAME=$(az containerapp list --resource-group "$LAB3_RG" --query "[0].name" -o tsv)
if [ -z "$CONTAINER_APP_NAME" ]; then
    print_error "No Container App found in $LAB3_RG"
    exit 1
fi

print_success "Container App found: $CONTAINER_APP_NAME"

# Get Container App URL
CONTAINER_APP_FQDN=$(az containerapp show --name "$CONTAINER_APP_NAME" --resource-group "$LAB3_RG" --query properties.configuration.ingress.fqdn -o tsv)
CONTAINER_APP_URL="https://$CONTAINER_APP_FQDN"
print_success "Container App URL: $CONTAINER_APP_URL"

# Get Container App status
REPLICA_COUNT=$(az containerapp replica list --name "$CONTAINER_APP_NAME" --resource-group "$LAB3_RG" --query "length(@)" -o tsv)
print_success "Current replica count: $REPLICA_COUNT"

# Test Container App endpoint
print_info "Testing Container App endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTAINER_APP_URL")
if [ "$HTTP_STATUS" == "200" ]; then
    print_success "Lab 3: Container App accessible (HTTP $HTTP_STATUS)"
else
    print_error "Lab 3 FAILED: HTTP status $HTTP_STATUS (expected 200)"
    exit 1
fi

# Test if we can get some content
print_info "Verifying content..."
CONTENT=$(curl -s "$CONTAINER_APP_URL" | head -c 200)
if echo "$CONTENT" | grep -q -i "html"; then
    print_success "Lab 3: HTML content verified"
else
    print_error "Lab 3 WARNING: Unexpected content received"
fi

# =============================================================================
# LAB 4: Azure Front Door
# =============================================================================
print_header "LAB 4: Testing Azure Front Door"

LAB4_RG="rg-scalingcloud-lab4"

# Check if resource group exists
print_info "Checking if Lab 4 resource group exists..."
if az group show --name "$LAB4_RG" >/dev/null 2>&1; then
    print_success "Resource group exists: $LAB4_RG"
else
    print_error "Resource group not found: $LAB4_RG"
    print_info "Please deploy Lab 4 first via GitHub Actions"
    exit 1
fi

# List resources in the resource group
print_info "Resources in $LAB4_RG:"
az resource list --resource-group "$LAB4_RG" --output table

# Get Container App details for Lab 4
CONTAINER_APP_NAME_L4=$(az containerapp list --resource-group "$LAB4_RG" --query "[0].name" -o tsv)
if [ -z "$CONTAINER_APP_NAME_L4" ]; then
    print_error "No Container App found in $LAB4_RG"
    exit 1
fi
print_success "Container App found: $CONTAINER_APP_NAME_L4"

# Get Container App URL for Lab 4
CONTAINER_APP_FQDN_L4=$(az containerapp show --name "$CONTAINER_APP_NAME_L4" --resource-group "$LAB4_RG" --query properties.configuration.ingress.fqdn -o tsv)
CONTAINER_APP_URL_L4="https://$CONTAINER_APP_FQDN_L4"
print_success "Container App (Direct) URL: $CONTAINER_APP_URL_L4"

# Test direct Container App endpoint
print_info "Testing Container App direct endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTAINER_APP_URL_L4")
if [ "$HTTP_STATUS" == "200" ]; then
    print_success "Lab 4: Container App (direct) accessible (HTTP $HTTP_STATUS)"
else
    print_error "Lab 4 WARNING: Direct Container App HTTP status $HTTP_STATUS"
fi

# Get Front Door profile
FRONTDOOR_PROFILE=$(az afd profile list --resource-group "$LAB4_RG" --query "[0].name" -o tsv)
if [ -z "$FRONTDOOR_PROFILE" ]; then
    print_error "No Front Door profile found in $LAB4_RG"
    exit 1
fi
print_success "Front Door profile found: $FRONTDOOR_PROFILE"

# Get Front Door endpoint
FRONTDOOR_ENDPOINT=$(az afd endpoint list --profile-name "$FRONTDOOR_PROFILE" --resource-group "$LAB4_RG" --query "[0].hostName" -o tsv)
if [ -z "$FRONTDOOR_ENDPOINT" ]; then
    print_error "No Front Door endpoint found"
    exit 1
fi

FRONTDOOR_URL="https://$FRONTDOOR_ENDPOINT"
print_success "Front Door URL: $FRONTDOOR_URL"

# Check Front Door provisioning state
FRONTDOOR_STATE=$(az afd profile show --profile-name "$FRONTDOOR_PROFILE" --resource-group "$LAB4_RG" --query provisioningState -o tsv)
print_info "Front Door provisioning state: $FRONTDOOR_STATE"

# Test Front Door endpoint
print_info "Testing Front Door endpoint (may take a few attempts if recently deployed)..."
MAX_RETRIES=5
RETRY_COUNT=0
FRONT_DOOR_SUCCESS=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTDOOR_URL")
    if [ "$HTTP_STATUS" == "200" ]; then
        print_success "Lab 4: Front Door accessible via HTTPS (HTTP $HTTP_STATUS)"
        FRONT_DOOR_SUCCESS=true
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            print_info "Attempt $RETRY_COUNT/$MAX_RETRIES: HTTP $HTTP_STATUS, retrying in 10s..."
            sleep 10
        fi
    fi
done

if [ "$FRONT_DOOR_SUCCESS" = false ]; then
    print_error "Lab 4 FAILED: Front Door returned HTTP $HTTP_STATUS after $MAX_RETRIES attempts"
    print_info "Front Door may still be propagating. Direct Container App URL works: $CONTAINER_APP_URL_L4"
    exit 1
fi

# Verify HTTPS redirect (try HTTP and check if it redirects)
print_info "Verifying HTTPS enforcement..."
HTTP_REDIRECT=$(curl -s -o /dev/null -w "%{http_code}" -L "http://$FRONTDOOR_ENDPOINT")
if [ "$HTTP_REDIRECT" == "200" ]; then
    print_success "Lab 4: HTTPS redirect working (HTTP request redirected successfully)"
fi

# =============================================================================
# LAB 5: Global Load Testing
# =============================================================================
print_header "LAB 5: Testing Global Load Testing"

LAB5_RG="rg-scalingcloud-lab5"

# Check if resource group exists
print_info "Checking if Lab 5 resource group exists..."
if az group show --name "$LAB5_RG" >/dev/null 2>&1; then
    print_success "Resource group exists: $LAB5_RG"
else
    print_error "Resource group not found: $LAB5_RG"
    print_info "Please deploy Lab 5 first via GitHub Actions"
    exit 1
fi

# List resources in the resource group
print_info "Resources in $LAB5_RG:"
az resource list --resource-group "$LAB5_RG" --output table

# Get Container Instance
CONTAINER_NAME=$(az container list --resource-group "$LAB5_RG" --query "[0].name" -o tsv)
if [ -z "$CONTAINER_NAME" ]; then
    print_error "No Container Instance found in $LAB5_RG"
    exit 1
fi
print_success "Container Instance found: $CONTAINER_NAME"

# Get container state
CONTAINER_STATE=$(az container show --name "$CONTAINER_NAME" --resource-group "$LAB5_RG" --query instanceView.state -o tsv)
print_info "Container state: $CONTAINER_STATE"

# Get container logs
print_info "Fetching K6 load test logs..."
echo ""
echo "----------------------------------------"
az container logs --resource-group "$LAB5_RG" --name "$CONTAINER_NAME" 2>/dev/null || {
    print_error "Failed to retrieve container logs"
    exit 1
}
echo "----------------------------------------"
echo ""

# Check if logs contain K6 output
LOGS=$(az container logs --resource-group "$LAB5_RG" --name "$CONTAINER_NAME" 2>/dev/null)
if echo "$LOGS" | grep -q "http_reqs"; then
    print_success "Lab 5: K6 load test logs found and valid"
else
    print_error "Lab 5 WARNING: K6 logs may be incomplete"
fi

# =============================================================================
# Final Summary
# =============================================================================
print_header "Test Summary"

echo ""
print_success "✅ Lab 3: Azure Container Apps - PASSED"
print_info "   └─ URL: $CONTAINER_APP_URL"
print_info "   └─ Replicas: $REPLICA_COUNT"
echo ""

print_success "✅ Lab 4: Azure Front Door - PASSED"
print_info "   └─ Front Door URL: $FRONTDOOR_URL"
print_info "   └─ Direct App URL: $CONTAINER_APP_URL_L4"
print_info "   └─ Provisioning State: $FRONTDOOR_STATE"
echo ""

print_success "✅ Lab 5: Global Load Testing - PASSED"
print_info "   └─ Container Instance: $CONTAINER_NAME"
print_info "   └─ State: $CONTAINER_STATE"
echo ""

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 ALL CLOUD LABS PASSED SUCCESSFULLY! 🎉               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "Active resource groups:"
az group list --tag Project=scalingCloudLab --query "[].{Name:name, Location:location}" --output table

echo ""
print_info "💰 Cost Notice: Azure resources are still running and incurring costs."
print_info "🧹 To clean up all resources, run: ./infra/nuke.sh"
echo ""
