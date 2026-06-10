#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Linux Bootstrap Started: $(date) ==="

# ─── Package manager detection ───────────────────────────────────────────────
# Resolve early so pkg_install is available before SCRIPT_DIR is set.

_bootstrap_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/pkg.sh"
if [[ -f "$_bootstrap_lib" ]]; then
    source "$_bootstrap_lib"
else
    # Running via curl pipe — lib not yet available; do minimal detection.
    if command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    else
        echo "❌ No supported package manager found (pacman, dnf, apt-get)"
        exit 1
    fi
    pkg_install() {
        case "$PKG_MANAGER" in
            pacman) sudo pacman -S --needed --noconfirm "$@" ;;
            dnf)    sudo dnf install -y "$@" ;;
            apt)    sudo apt-get install -y "$@" ;;
        esac
    }
fi
export PKG_MANAGER

# ─── Resolve script directory (safe under both `bash file.sh` and curl-pipe) ─

if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ "${BASH_SOURCE[0]}" != "bash" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR=""
fi

# ─── If subscripts aren't alongside us, we're running via curl pipe ───────────
# Install git, clone the repo, and re-exec from the real directory.

BOOTSTRAP_REPO="https://github.com/DraconicAspirations/linux-bootstrap.git"
BOOTSTRAP_DIR="$HOME/linux-bootstrap"

if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/github-connect.sh" ]]; then
    echo "🌐 Running via curl — installing git and cloning bootstrap repo…"
    pkg_install git

    if [[ -d "$BOOTSTRAP_DIR/.git" ]]; then
        git -C "$BOOTSTRAP_DIR" pull
    else
        git clone "$BOOTSTRAP_REPO" "$BOOTSTRAP_DIR"
    fi

    echo "🔄 Re-launching from cloned repo…"
    exec bash "$BOOTSTRAP_DIR/bootstrap.sh"
fi

# ─── Run the three setup scripts in order ────────────────────────────────────

echo "🔑 Step 1: GitHub SSH Setup"
bash "$SCRIPT_DIR/github-connect.sh"

echo ""
echo "⏸️  Please add your SSH public key to GitHub if you haven't already."
echo "   https://github.com/settings/keys"
read -p "Press Enter once the key is added to continue…" < /dev/tty

echo ""
echo "📥 Step 2: Sync dotfiles from linux-sync repo"
bash "$SCRIPT_DIR/sync-home.sh"

echo ""
echo "📦 Step 3: Install packages and setup environment"
bash "$SCRIPT_DIR/setup-home.sh"

echo ""
echo "=== Bootstrap Complete! ==="
echo ""
echo "⚠️  IMPORTANT: You must reboot for all changes to take effect."
echo "   Run: sudo reboot"
echo ""
