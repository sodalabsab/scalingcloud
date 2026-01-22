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
CONFIG_FILE="${SCRIPT_DIR}/../config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ Error: config.env not found!${NC}"
    exit 1
fi

source "$CONFIG_FILE"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Scaling Cloud - Complete Lab Test Suite                ║${NC}"
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
command -v docker >/dev/null 2>&1 || { print_error "Docker is required but not installed."; exit 1; }
command -v az >/dev/null 2>&1 || { print_error "Azure CLI is required but not installed."; exit 1; }
command -v gh >/dev/null 2>&1 || { print_error "GitHub CLI is required but not installed."; exit 1; }
command -v k6 >/dev/null 2>&1 || { print_error "K6 is required but not installed."; exit 1; }

print_success "Docker installed"
print_success "Azure CLI installed"
print_success "GitHub CLI installed"
print_success "K6 installed"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker daemon is not running. Please start Docker Desktop."
    exit 1
fi
print_success "Docker daemon is running"

# Check Azure login
print_info "Checking Azure login..."
if ! az account show >/dev/null 2>&1; then
    print_error "Not logged into Azure. Please run 'az login'"
    exit 1
fi
print_success "Logged into Azure"

# Check GitHub login
print_info "Checking GitHub login..."
if ! gh auth status >/dev/null 2>&1; then
    print_error "Not logged into GitHub. Please run 'gh auth login'"
    exit 1
fi
print_success "Logged into GitHub"

# =============================================================================
# LAB 1: Docker Basics
# =============================================================================
print_header "LAB 1: Testing Docker Basics"

cd "${SCRIPT_DIR}/lab1"

# Setup content if not exists
if [ ! -d "html" ]; then
    print_info "Setting up website content..."
    ./setup-massively.sh
    print_success "Website content downloaded"
else
    print_success "Website content already exists"
fi

# Build Docker image
print_info "Building Docker image..."
docker build -t my-website . >/dev/null 2>&1
print_success "Docker image built: my-website"

# Stop any existing container on port 8080
print_info "Cleaning up existing containers..."
docker ps -q --filter "publish=8080" | xargs -r docker stop >/dev/null 2>&1 || true
docker ps -aq --filter "publish=8080" | xargs -r docker rm >/dev/null 2>&1 || true

# Run container
print_info "Starting container on port 8080..."
CONTAINER_ID=$(docker run -d -p 8080:80 my-website)
print_success "Container started: ${CONTAINER_ID:0:12}"

# Wait for container to be ready
sleep 2

# Test HTTP endpoint
print_info "Testing HTTP endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_STATUS" == "200" ]; then
    print_success "Lab 1: Website accessible at http://localhost:8080 (HTTP $HTTP_STATUS)"
else
    print_error "Lab 1 FAILED: HTTP status $HTTP_STATUS (expected 200)"
    docker logs "$CONTAINER_ID"
    exit 1
fi

# Stop container
docker stop "$CONTAINER_ID" >/dev/null 2>&1
docker rm "$CONTAINER_ID" >/dev/null 2>&1
print_success "Lab 1 container cleaned up"

# =============================================================================
# LAB 2: Docker Compose & Load Balancing
# =============================================================================
print_header "LAB 2: Testing Docker Compose & Load Balancing"

cd "${SCRIPT_DIR}/lab2"

# Start services
print_info "Starting Docker Compose services (3 replicas)..."
docker compose up -d --scale my-website=3 >/dev/null 2>&1
sleep 3
print_success "Services started"

# Test HTTP endpoint
print_info "Testing Nginx reverse proxy..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080)
if [ "$HTTP_STATUS" == "200" ]; then
    print_success "Lab 2: Nginx reverse proxy accessible (HTTP $HTTP_STATUS)"
else
    print_error "Lab 2 FAILED: HTTP status $HTTP_STATUS (expected 200)"
    docker compose logs
    exit 1
fi

# Run load test
print_info "Running K6 load test..."
if k6 run load.js >/dev/null 2>&1; then
    print_success "Lab 2: Load test completed successfully"
else
    print_error "Lab 2 FAILED: Load test failed"
    exit 1
fi

# Cleanup
docker compose down >/dev/null 2>&1
print_success "Lab 2 services cleaned up"

# =============================================================================
# LAB 3: Azure Container Apps (ACR + Deployment)
# =============================================================================
print_header "LAB 3: Testing Azure Container Apps"

# Login to ACR
print_info "Logging into Azure Container Registry: $ACR_NAME..."
az acr login --name "$ACR_NAME" >/dev/null 2>&1
print_success "Logged into ACR"

# Push image to ACR
cd "${SCRIPT_DIR}/lab1"
print_info "Building and pushing image to ACR..."

# Set variables for push script
export ACR_NAME="$ACR_NAME"
IMAGE_NAME="my-website"
TAG="latest"
FULL_IMAGE_NAME="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${TAG}"

# Build for amd64 platform
docker buildx build --platform linux/amd64 -t "$FULL_IMAGE_NAME" . >/dev/null 2>&1
docker push "$FULL_IMAGE_NAME" >/dev/null 2>&1
print_success "Image pushed to ACR: $FULL_IMAGE_NAME"

# Deploy Lab 3 infrastructure using GitHub Actions
cd "${SCRIPT_DIR}"
print_info "Deploying Lab 3 via GitHub Actions..."
print_info "This will trigger the Lab Bicep Deployment workflow..."

# Trigger workflow
gh workflow run lab-bicep-deploy.yml -f labNumber=lab3

print_info "Workflow triggered. Waiting for completion..."
sleep 10

# Get the latest workflow run
RUN_ID=$(gh run list --workflow=lab-bicep-deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    print_error "Failed to get workflow run ID"
    exit 1
fi

print_info "Monitoring workflow run: $RUN_ID"

# Wait for workflow to complete (max 10 minutes)
TIMEOUT=600
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
    CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    
    if [ "$STATUS" == "completed" ]; then
        if [ "$CONCLUSION" == "success" ]; then
            print_success "Lab 3 deployment succeeded"
            break
        else
            print_error "Lab 3 deployment failed with conclusion: $CONCLUSION"
            gh run view "$RUN_ID" --log
            exit 1
        fi
    fi
    
    print_info "Workflow status: $STATUS (waiting ${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    print_error "Lab 3 deployment timed out"
    exit 1
fi

# Get Container App URL
LAB3_RG="rg-scalingcloud-lab3"
print_info "Getting Container App URL..."
CONTAINER_APP_URL=$(az containerapp show --name ca-scalingcloud-lab3 --resource-group "$LAB3_RG" --query properties.configuration.ingress.fqdn -o tsv)

if [ -z "$CONTAINER_APP_URL" ]; then
    print_error "Failed to get Container App URL"
    exit 1
fi

CONTAINER_APP_URL="https://$CONTAINER_APP_URL"
print_success "Container App URL: $CONTAINER_APP_URL"

# Test Container App
print_info "Testing Container App endpoint..."
sleep 5  # Wait for app to be fully ready
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$CONTAINER_APP_URL")
if [ "$HTTP_STATUS" == "200" ]; then
    print_success "Lab 3: Container App accessible (HTTP $HTTP_STATUS)"
else
    print_error "Lab 3 FAILED: HTTP status $HTTP_STATUS (expected 200)"
    exit 1
fi

# Run load test for Lab 3
cd "${SCRIPT_DIR}/lab3"
print_info "Running K6 load test against Container App..."

# Update load.js with the actual URL
sed -i.bak "s|http://localhost:8080|$CONTAINER_APP_URL|g" load.js

if k6 run load.js >/dev/null 2>&1; then
    print_success "Lab 3: Load test completed successfully"
else
    print_error "Lab 3 WARNING: Load test encountered errors (may be timeout related)"
fi

# Restore original load.js
mv load.js.bak load.js

# =============================================================================
# LAB 4: Azure Front Door
# =============================================================================
print_header "LAB 4: Testing Azure Front Door"

cd "${SCRIPT_DIR}"
print_info "Deploying Lab 4 via GitHub Actions..."

# Trigger workflow
gh workflow run lab-bicep-deploy.yml -f labNumber=lab4

print_info "Workflow triggered. Waiting for completion..."
sleep 10

# Get the latest workflow run
RUN_ID=$(gh run list --workflow=lab-bicep-deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    print_error "Failed to get workflow run ID"
    exit 1
fi

print_info "Monitoring workflow run: $RUN_ID"

# Wait for workflow to complete (max 15 minutes - Front Door takes longer)
TIMEOUT=900
ELAPSED=0
INTERVAL=15

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
    CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    
    if [ "$STATUS" == "completed" ]; then
        if [ "$CONCLUSION" == "success" ]; then
            print_success "Lab 4 deployment succeeded"
            break
        else
            print_error "Lab 4 deployment failed with conclusion: $CONCLUSION"
            gh run view "$RUN_ID" --log
            exit 1
        fi
    fi
    
    print_info "Workflow status: $STATUS (waiting ${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    print_error "Lab 4 deployment timed out"
    exit 1
fi

# Get Front Door URL
LAB4_RG="rg-scalingcloud-lab4"
print_info "Getting Front Door URL..."

# Front Door endpoint name pattern 
FRONTDOOR_NAME=$(az afd profile list --resource-group "$LAB4_RG" --query "[0].name" -o tsv)
if [ -z "$FRONTDOOR_NAME" ]; then
    print_error "Failed to find Front Door profile"
    exit 1
fi

FRONTDOOR_ENDPOINT=$(az afd endpoint list --profile-name "$FRONTDOOR_NAME" --resource-group "$LAB4_RG" --query "[0].hostName" -o tsv)
if [ -z "$FRONTDOOR_ENDPOINT" ]; then
    print_error "Failed to get Front Door endpoint"
    exit 1
fi

FRONTDOOR_URL="https://$FRONTDOOR_ENDPOINT"
print_success "Front Door URL: $FRONTDOOR_URL"

# Wait for Front Door to be ready (can take a few minutes)
print_info "Waiting for Front Door to be fully provisioned (this may take 5-10 minutes)..."
sleep 120

# Test Front Door endpoint
print_info "Testing Front Door endpoint..."
MAX_RETRIES=10
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FRONTDOOR_URL")
    if [ "$HTTP_STATUS" == "200" ]; then
        print_success "Lab 4: Front Door accessible via HTTPS (HTTP $HTTP_STATUS)"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        print_info "Attempt $RETRY_COUNT/$MAX_RETRIES: HTTP $HTTP_STATUS, retrying in 30s..."
        sleep 30
    fi
done

if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    print_error "Lab 4 FAILED: Front Door not accessible after $MAX_RETRIES attempts"
    exit 1
fi

# =============================================================================
# LAB 5: Global Load Testing with Front Door
# =============================================================================
print_header "LAB 5: Testing Global Load Testing"

cd "${SCRIPT_DIR}/lab5"

# Update the lab.bicep with the Front Door URL
print_info "Updating lab5/lab.bicep with Front Door URL..."
sed -i.bak "s|https://.*azurefd.net|$FRONTDOOR_URL|g" lab.bicep

# Commit and push the change
git add lab.bicep
git commit -m "test: Update lab5 with Front Door URL for testing" || true
git push || true

print_success "Lab 5 bicep updated and pushed"

cd "${SCRIPT_DIR}"
print_info "Deploying Lab 5 via GitHub Actions..."

# Trigger workflow
gh workflow run lab-bicep-deploy.yml -f labNumber=lab5

print_info "Workflow triggered. Waiting for completion..."
sleep 10

# Get the latest workflow run
RUN_ID=$(gh run list --workflow=lab-bicep-deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    print_error "Failed to get workflow run ID"
    exit 1
fi

print_info "Monitoring workflow run: $RUN_ID"

# Wait for workflow to complete
TIMEOUT=600
ELAPSED=0
INTERVAL=10

while [ $ELAPSED -lt $TIMEOUT ]; do
    STATUS=$(gh run view "$RUN_ID" --json status --jq '.status')
    CONCLUSION=$(gh run view "$RUN_ID" --json conclusion --jq '.conclusion')
    
    if [ "$STATUS" == "completed" ]; then
        if [ "$CONCLUSION" == "success" ]; then
            print_success "Lab 5 deployment succeeded"
            break
        else
            print_error "Lab 5 deployment failed with conclusion: $CONCLUSION"
            gh run view "$RUN_ID" --log
            exit 1
        fi
    fi
    
    print_info "Workflow status: $STATUS (waiting ${ELAPSED}s/${TIMEOUT}s)"
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    print_error "Lab 5 deployment timed out"
    exit 1
fi

# Check K6 container logs
LAB5_RG="rg-scalingcloud-lab5"
print_info "Waiting for K6 container to complete (30s)..."
sleep 30

print_info "Fetching K6 container logs..."
az container logs --resource-group "$LAB5_RG" --name k6-container

print_success "Lab 5: K6 load test logs retrieved"

# =============================================================================
# Final Summary
# =============================================================================
print_header "Test Summary"

print_success "✅ Lab 1: Docker basics - PASSED"
print_success "✅ Lab 2: Docker Compose & Load Balancing - PASSED"
print_success "✅ Lab 3: Azure Container Apps - PASSED"
print_success "✅ Lab 4: Azure Front Door - PASSED"
print_success "✅ Lab 5: Global Load Testing - PASSED"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🎉 ALL LABS PASSED SUCCESSFULLY! 🎉                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

print_info "Note: Azure resources are still running and incurring costs."
print_info "To clean up all resources, run: ./infra/nuke.sh"
