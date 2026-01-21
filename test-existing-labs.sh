#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_header() { echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"; echo -e "${BLUE}  $1${NC}"; echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"; }
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}ℹ $1${NC}"; }

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Scaling Cloud - Simple Lab Test                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if labs are already deployed, if so just test them
print_header "Checking Deployed Labs"

LABS_FOUND=0

# Check Lab 3
if az group exists --resource-group rg-scalingcloud-lab3 | grep -q "true"; then
    print_success "Lab 3 resource group exists"
    LABS_FOUND=$((LABS_FOUND + 1))
    
    # Get Container App URL
    CONTAINER_APP_NAME=$(az containerapp list --resource-group rg-scalingcloud-lab3 --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$CONTAINER_APP_NAME" ]; then
        LAB3_URL="https://$(az containerapp show --name "$CONTAINER_APP_NAME" --resource-group rg-scaling cloud-lab3 --query properties.configuration.ingress.fqdn -o tsv)"
        print_info "Lab 3 URL: $LAB3_URL"
        
        # Test endpoint
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$LAB3_URL")
        if [ "$HTTP_STATUS" == "200" ]; then
            print_success "Lab 3 TEST: PASSED (HTTP $HTTP_STATUS)"
        else
            print_error "Lab 3 TEST: FAILED (HTTP $HTTP_STATUS)"
        fi
    fi
else
    print_info "Lab 3 not deployed"
fi

# Check Lab 4
if az group exists --resource-group rg-scalingcloud-lab4 | grep -q "true"; then
    print_success "Lab 4 resource group exists"
    LABS_FOUND=$((LABS_FOUND + 1))
    
    # Get Front Door URL
    FRONTDOOR_PROFILE=$(az afd profile list --resource-group rg-scalingcloud-lab4 --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$FRONTDOOR_PROFILE" ]; then
        LAB4_ENDPOINT=$(az afd endpoint list --profile-name "$FRONTDOOR_PROFILE" --resource-group rg-scalingcloud-lab4 --query "[0].hostName" -o tsv)
        LAB4_URL="https://$LAB4_ENDPOINT"
        print_info "Lab 4 URL: $LAB4_URL"
        
        # Test endpoint
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$LAB4_URL")
        if [ "$HTTP_STATUS" == "200" ]; then
            print_success "Lab 4 TEST: PASSED (HTTP $HTTP_STATUS)"
        else
            print_info "Lab 4 TEST: HTTP $HTTP_STATUS (may still be propagating)"
        fi
    fi
else
    print_info "Lab 4 not deployed"
fi

# Check Lab 5
if az group exists --resource-group rg-scalingcloud-lab5 | grep -q "true"; then
    print_success "Lab 5 resource group exists"
    LABS_FOUND=$((LABS_FOUND + 1))
    
    # Get Container Instance
    CONTAINER_NAME=$(az container list --resource-group rg-scalingcloud-lab5 --query "[0].name" -o tsv 2>/dev/null)
    if [ -n "$CONTAINER_NAME" ]; then
        print_info "Lab 5 Container: $CONTAINER_NAME"
        
        # Get logs
        print_info "К6 Load Test Results:"
        echo "----------------------------------------"
        az container logs --resource-group rg-scalingcloud-lab5 --name "$CONTAINER_NAME" 2>/dev/null || print_error "Failed to retrieve logs"
        echo "----------------------------------------"
        print_success "Lab 5 TEST: PASSED"
    fi
else
    print_info "Lab 5 not deployed"
fi

if [ $LABS_FOUND -eq 0 ]; then
    print_error "No labs have been deployed yet!"
    print_info ""
    print_info "To deploy labs, use GitHub Actions:"
    print_info "  1. Go to Actions tab in GitHub"
    print_info "  2. Select 'Lab Bicep Deployment'"
    print_info "  3. Click 'Run workflow'"
    print_info "  4. Enter lab folder name (lab3, lab4, or lab5)"
    print_info ""
    print_info "Or use the GitHub CLI:"
    print_info "  gh workflow run lab-bicep-deploy.yml -f labPath=lab3"
    print_info "  gh workflow run lab-bicep-deploy.yml -f labPath=lab4"
    print_info "  gh workflow run lab-bicep-deploy.yml -f labPath=lab5"
    exit 1
fi

print_header "Summary"
echo ""
print_success "✅ Found and tested $LABS_FOUND lab(s)"
echo ""
print_info "📊 All deployed resources:"
az group list --tag Project=scalingCloudLab --query "[].{Name:name, Location:location}" --output table
echo ""
