# 1. Get the current Subscription ID for safety display
$SUB_ID = (az account show --query id -o tsv)
$SUB_NAME = (az account show --query name -o tsv)

Write-Host "⚠️  WARNING: YOU ARE ABOUT TO DELETE ALL RESOURCE GROUPS ⚠️"
Write-Host "   Subscription: $SUB_NAME ($SUB_ID)"
Write-Host ""

# 2. List all Resource Groups
Write-Host "🔍 Fetching Resource Groups..."
# Force array type to handle 0, 1, or multiple results consistently
$RGS = @(az group list --query "[].name" -o tsv)

if ($RGS.Count -eq 0 -or [string]::IsNullOrWhiteSpace($RGS[0])) {
    Write-Host "✅ No Resource Groups found. Your subscription is clean."
    exit 0
}

# 3. Show what will be deleted
Write-Host "❌ The following Resource Groups will be PERMANENTLY DELETED:"
Write-Host "-------------------------------------------------------------"
$RGS | ForEach-Object { Write-Host $_ }
Write-Host "-------------------------------------------------------------"

# 4. Force Confirmation
$CONFIRM = Read-Host "are you absolutely sure? (Type 'yes' to proceed)"
if ($CONFIRM -ne "yes") {
    Write-Host "🚫 Operation cancelled."
    exit 1
}

# 5. The Delete Loop
Write-Host ""
Write-Host "🚀 Nuke launched..."

foreach ($rg in $RGS) {
    if (-not [string]::IsNullOrWhiteSpace($rg)) {
        Write-Host "   ...Deleting $rg (Background job)"
        # --no-wait returns control immediately so we can start deleting the next one
        # --yes skips the interactive CLI confirmation
        az group delete --name "$rg" --yes --no-wait
    }
}

Write-Host ""
Write-Host "✅ Delete commands issued for all groups."
Write-Host "   Azure is now deleting them in the background. This may take a few minutes."
