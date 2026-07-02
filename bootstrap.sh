#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Linux Bootstrap Started: $(date) ==="

source ./pkg.sh

export PKG_MANAGER

echo "🔑 Step 1: GitHub SSH Setup"
bash ./github-connect.sh

echo ""
echo "📥 Step 2: Sync dotfiles from linux-sync repo"
bash ./sync-home.sh

echo ""
echo "📦 Step 3: Install packages and setup environment"
bash ./call-self-setup.sh

echo ""
echo "✅ Linux Bootstrap Complete"