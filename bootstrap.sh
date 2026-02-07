#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Linux Bootstrap Started: $(date) ==="

# ───────────────────────────────────────────────
# 0. Sanity Checks
# ───────────────────────────────────────────────

if ! command -v pacman >/dev/null; then
    echo "❌ This system does not appear to be Arch-based. Aborting."
    exit 1
fi

# ───────────────────────────────────────────────
# 1. Get script directory
# ───────────────────────────────────────────────

SCRIPT_DIR="$(cd ""+"(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ───────────────────────────────────────────────
# 2. Run the three setup scripts in order
# ───────────────────────────────────────────────

echo "🔑 Step 1: GitHub SSH Setup"
bash "$SCRIPT_DIR/github-connect.sh"

echo ""
echo "📥 Step 2: Sync dotfiles from linux-sync repo"
bash "$SCRIPT_DIR/sync-home.sh"

echo ""
echo "📦 Step 3: Install packages and setup environment"
bash "$SCRIPT_DIR/setup-home.sh"

echo ""
echo "=== Bootstrap Complete! ==="
echo "Restart your terminal.",