#!/bin/bash

# Configuration
REPO_NAME="aca-demo"
RESOURCE_GROUP="rg-aca-platform"
GITHUB_USER=$(gh api user -q .login)

echo "⚠️  WARNING: This script will delete EVERYTHING associated with this lab."
echo "   - GitHub Repository: $GITHUB_USER/$REPO_NAME"
echo "   - Azure Resource Group: $RESOURCE_GROUP"
echo "   - Local Git configuration"
echo ""
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

echo "DESTROYING LAB ENVIRONMENT..."

# 1. Delete GitHub Repository
echo "🗑 Deleting GitHub Repository..."
if gh repo delete "$GITHUB_USER/$REPO_NAME" --yes; then
    echo "✓ Repository deleted."
else
    echo "❌ Failed to delete repository."
    echo "⚠️  Common Error: HTTP 403 'Must have admin rights to Repository'"
    echo "   Solution: Run the following command to grant delete permissions:"
    echo "   gh auth refresh -h github.com -s delete_repo"
fi

# 2. Delete Azure Resources
echo "cloud Deleting Azure Resource Group (this runs in the background)..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait || echo "Resource group not found."

# 3. Reset Local State
echo "🧹 Cleaning up local git..."
rm -rf .git

echo "✅ Teardown initiated. Azure resources will disappear shortly."
echo "You can now start the lab from scratch!"
