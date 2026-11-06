#!/usr/bin/env bash
# ==============================================================================
# Helper Script: Setup Git Hooks for Secret Scanning (POSIX / macOS / Linux / Git Bash)
# ==============================================================================

set -e

echo "🚀 Setting up Git pre-commit hooks for Betterleaks secret scanning..."

# Check if git is available
if ! command -v git >/dev/null 2>&1; then
    echo "❌ Git is not installed or not in PATH."
    exit 1
fi

# Configure git to use .githooks directory
git config core.hooksPath .githooks
echo "✅ Configured 'git config core.hooksPath .githooks'"

# Ensure pre-commit hook has executable permissions
if [ -f ".githooks/pre-commit" ]; then
    chmod +x .githooks/pre-commit
    echo "✅ Set executable permissions on .githooks/pre-commit"
fi

# Check if Betterleaks CLI is installed
if command -v betterleaks >/dev/null 2>&1; then
    VERSION=$(betterleaks --version 2>&1 || true)
    echo "✅ Betterleaks CLI detected: $VERSION"
else
    echo "⚠️  Betterleaks CLI is not currently found in your PATH."
    echo "   Install it to activate local secret scanning:"
    echo "     macOS:   brew install betterleaks"
    echo "     Linux:   curl -sSfL https://github.com/betterleaks/betterleaks/releases/latest/download/... | tar -xz"
    echo "     Windows: scoop install betterleaks"
    echo "   See docs/SECRET_SCANNING_DEVELOPER_GUIDE.md for step-by-step instructions."
fi

echo "🎉 Pre-commit hook setup complete! Every 'git commit' will now scan staged files."

