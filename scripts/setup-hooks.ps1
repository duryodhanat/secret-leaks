# ==============================================================================
# Helper Script: Setup Git Hooks for Secret Scanning (Windows PowerShell)
# ==============================================================================

Write-Host "🚀 Setting up Git pre-commit hooks for Betterleaks secret scanning..." -ForegroundColor Cyan

# Check if git command exists
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git is not installed or not in PATH." -ForegroundColor Red
    exit 1
}

# Configure Git to use the version-controlled .githooks directory
git config core.hooksPath .githooks
Write-Host "✅ Configured 'git config core.hooksPath .githooks'" -ForegroundColor Green

# Check if Betterleaks CLI is installed
if (Get-Command betterleaks -ErrorAction SilentlyContinue) {
    $ver = & betterleaks --version 2>&1
    Write-Host "✅ Betterleaks CLI detected: $ver" -ForegroundColor Green
} else {
    Write-Host "⚠️  Betterleaks CLI is not currently found in your PATH." -ForegroundColor Yellow
    Write-Host "   Install it to activate local secret scanning:" -ForegroundColor Yellow
    Write-Host "     - Windows: scoop install betterleaks OR download binary from GitHub Releases" -ForegroundColor Yellow
    Write-Host "     - macOS:   brew install betterleaks" -ForegroundColor Yellow
    Write-Host "     - Linux:   curl -sSfL ... | tar -xz" -ForegroundColor Yellow
    Write-Host "   See docs/SECRET_SCANNING_DEVELOPER_GUIDE.md for step-by-step instructions." -ForegroundColor Yellow
}

Write-Host "🎉 Pre-commit hook setup complete! Every 'git commit' will now scan staged files." -ForegroundColor Cyan

