#!/bin/bash

# 1. Get the current Subscription ID for safety display
SUB_ID=$(az account show --query id -o tsv)
SUB_NAME=$(az account show --query name -o tsv)

echo "⚠️  WARNING: YOU ARE ABOUT TO DELETE ALL RESOURCE GROUPS ⚠️"
echo "   Subscription: $SUB_NAME ($SUB_ID)"
echo ""

# 2. List all Resource Groups
echo "🔍 Fetching Resource Groups..."
RGS=$(az group list --query "[].name" -o tsv)

if [ -z "$RGS" ]; then
    echo "✅ No Resource Groups found. Your subscription is clean."
    exit 0
fi

# 3. Show what will be deleted
echo "❌ The following Resource Groups will be PERMANENTLY DELETED:"
echo "-------------------------------------------------------------"
echo "$RGS"
echo "-------------------------------------------------------------"

# 4. Force Confirmation
read -p "are you absolutely sure? (Type 'yes' to proceed): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "🚫 Operation cancelled."
    exit 1
fi

# 5. The Delete Loop
echo ""
echo "🚀 Nuke launched..."

# We set Internal Field Separator to newline to handle names with spaces (though rare in RGs)
IFS=$'\n'
for rg in $RGS; do
    echo "   ...Deleting $rg (Background job)"
    # --no-wait returns control immediately so we can start deleting the next one
    # --yes skips the interactive CLI confirmation
    az group delete --name "$rg" --yes --no-wait
done
unset IFS

echo ""
echo "✅ Delete commands issued for all groups."
echo "   Azure is now deleting them in the background. This may take a few minutes."