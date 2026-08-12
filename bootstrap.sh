#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/DraconicAspirations/unix-bootstrap.git"

# When bootstrap.sh is run directly from GitHub (for example via curl), the
# rest of the repository is not present yet. Git is required to fetch it.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v sudo >/dev/null 2>&1; then
    echo "⚠️  sudo is required to bootstrap this system, but it is not installed."
    echo "Please install sudo and run bootstrap.sh again."
    exit 1
fi

if [[ ! -f "$SCRIPT_DIR/pkg.sh" ]]; then
    if ! command -v git >/dev/null 2>&1; then
        echo "⚠️  Git is required to bootstrap this system, but it is not installed."
        echo "Please install Git with your system package manager and run bootstrap.sh again."
        exit 1
    fi

    BOOTSTRAP_DIR="$(mktemp -d)"
    trap 'rm -rf "$BOOTSTRAP_DIR"' EXIT

    echo "📥 Downloading unix-bootstrap..."
    git clone --depth 1 "$REPO" "$BOOTSTRAP_DIR/unix-bootstrap"

    exec bash "$BOOTSTRAP_DIR/unix-bootstrap/bootstrap.sh"
fi

cd "$SCRIPT_DIR"

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Linux Bootstrap Started: $(date) ==="

source "$SCRIPT_DIR/pkg.sh"

export PKG_MANAGER

echo "🔑 Step 1: GitHub SSH Setup"
bash "$SCRIPT_DIR/github-connect.sh"

echo ""
echo "📥 Step 2: Sync dotfiles from linux-sync repo"
echo "This may take a few minutes..."
bash "$SCRIPT_DIR/sync-home.sh"

echo ""
echo "📦 Step 3: Install packages and setup environment"
echo "This may take a few minutes..."
bash "$SCRIPT_DIR/call-self-setup.sh"

echo ""
echo "✅ Linux Bootstrap Complete"
