#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Linux Bootstrap Started: $(date) ==="

# ─── Resolve repo/script directories ─────────────────────────────────────────
# When run from a real checkout, these point to the repo and scripts directory.
# When run via curl pipe, they stay empty until the repo is cloned.

REPO_DIR=""
SCRIPT_DIR=""

if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "${BASH_SOURCE[0]}" ]]; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SCRIPT_DIR="$REPO_DIR/scripts"
fi

# ─── Package manager detection ───────────────────────────────────────────────
# Source the full package helper if available. During curl-pipe mode, lib/ is
# not available yet, so fall back to minimal detection.

_bootstrap_lib=""

if [[ -n "$REPO_DIR" ]]; then
    _bootstrap_lib="$REPO_DIR/lib/pkg.sh"
fi

if [[ -n "$_bootstrap_lib" && -f "$_bootstrap_lib" ]]; then
    source "$_bootstrap_lib"
else
    if command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    elif command -v apt-get >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    else
        echo "❌ No supported package manager found: pacman, dnf, apt-get"
        exit 1
    fi

    as_root() {
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
            "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            echo "❌ This script needs root privileges, but sudo is not installed."
            echo "   Re-run as root, or install sudo first."
            exit 1
        fi
    }

    pkg_update() {
        case "$PKG_MANAGER" in
            pacman) as_root pacman -Syu --noconfirm ;;
            dnf)    as_root dnf check-update || true ;;
            apt)    as_root apt-get update ;;
        esac
    }

    pkg_install() {
        case "$PKG_MANAGER" in
            pacman) as_root pacman -S --needed --noconfirm "$@" ;;
            dnf)    as_root dnf install -y "$@" ;;
            apt)    as_root apt-get install -y "$@" ;;
        esac
    }
fi

export PKG_MANAGER

# ─── If subscripts aren't alongside us, we're running via curl pipe ───────────
# Install git, clone the repo, and re-exec from the real directory.

BOOTSTRAP_REPO="https://github.com/DraconicAspirations/linux-bootstrap.git"
BOOTSTRAP_DIR="$HOME/linux-bootstrap"

if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/github-connect.sh" ]]; then
    echo "🌐 Running via curl or outside the repo — installing git and cloning bootstrap repo…"

    pkg_update
    pkg_install git

    if [[ -d "$BOOTSTRAP_DIR/.git" ]]; then
        echo "📁 Existing bootstrap repo found. Updating…"
        git -C "$BOOTSTRAP_DIR" pull --ff-only
    else
        echo "📥 Cloning bootstrap repo…"
        git clone "$BOOTSTRAP_REPO" "$BOOTSTRAP_DIR"
    fi

    echo "🔄 Re-launching from cloned repo…"
    exec bash "$BOOTSTRAP_DIR/bootstrap.sh"
fi

# ─── Run the setup scripts in order ──────────────────────────────────────────

echo "🔑 Step 1: GitHub SSH Setup"
bash "$SCRIPT_DIR/github-connect.sh"

echo ""
echo "📥 Step 2: Sync dotfiles from linux-sync repo"
bash "$SCRIPT_DIR/sync-home.sh"

echo ""
echo "📦 Step 3: Install packages and setup environment"
bash "$SCRIPT_DIR/call-self-setup.sh"

