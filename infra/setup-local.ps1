$ErrorActionPreference = "Stop"

Write-Host "🔍 Checking Local Development Prerequisites..." -ForegroundColor Yellow

# Check Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Git is not installed." -ForegroundColor Red
    exit 1
}
Write-Host "✅ Git is installed" -ForegroundColor Green

# Check Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: Docker is not installed." -ForegroundColor Red
    exit 1
}

# Check Docker Daemon
try {
    docker info | Out-Null
    Write-Host "✅ Docker is installed and running" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: Docker daemon is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check K6
if (-not (Get-Command k6 -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: k6 is not installed. (Required for Lab 2)" -ForegroundColor Red
    Write-Host "👉 Install k6: https://k6.io/docs/get-started/installation/" -ForegroundColor Yellow
    exit 1
}
Write-Host "✅ k6 is installed" -ForegroundColor Green

# Check GitHub CLI
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Warning: GitHub CLI ('gh') is not installed. (Required for Cloud Setup later)" -ForegroundColor Yellow
} else {
    Write-Host "✅ GitHub CLI is installed" -ForegroundColor Green
    try {
        gh auth status | Out-Null
        Write-Host "✅ Logged into GitHub" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Warning: You are not logged into GitHub. Run 'gh auth login' before Cloud Setup." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ Local Environment Configured!                        ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "   Git:    $(git --version)"
Write-Host "   Docker: $(docker --version)"
Write-Host "   K6:     $(k6 version)"
Write-Host ""
Write-Host "👉 You are now ready for Lab 1 and Lab 2!" -ForegroundColor Yellow
