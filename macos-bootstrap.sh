
#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/.bootstrap.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== macOS Bootstrap Started: $(date) ==="

# ───────────────────────────────────────────────
# 0. Get script directory
# ───────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ───────────────────────────────────────────────
# 1. Install / adopt Homebrew
# ───────────────────────────────────────────────

CURRENT_USER="$(whoami)"
IS_BREW_OWNER=false

if ! command -v brew >/dev/null; then
    echo "📦 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
    IS_BREW_OWNER=true
else
    BREW_PREFIX="$(brew --prefix)"
    BREW_OWNER="$(stat -f "%Su" "$BREW_PREFIX")"

    if [[ "$BREW_OWNER" == "$CURRENT_USER" ]]; then
        echo "✓ Homebrew already installed and owned by $CURRENT_USER"
        IS_BREW_OWNER=true
    else
        echo "⚠ Existing Homebrew installation detected (owned by $BREW_OWNER)."
        read -p "Transfer ownership to $CURRENT_USER? (y/n): " TRANSFER_BREW
        if [[ "$TRANSFER_BREW" =~ ^[Yy]$ ]]; then
            echo "🔑 Transferring Homebrew ownership to $CURRENT_USER..."
            sudo chown -R "$CURRENT_USER" "$BREW_PREFIX"
            echo "✓ Ownership transferred"
            IS_BREW_OWNER=true
        else
            echo "↩ Keeping existing ownership — assuming all packages already installed by $BREW_OWNER"
            IS_BREW_OWNER=false
        fi
    fi
fi

# ───────────────────────────────────────────────
# 2. Install / verify essential tools
# ───────────────────────────────────────────────

# If this user owns Homebrew, install packages normally.
# Otherwise, just verify they are present (installed by the brew owner).
verify_or_install() {
    local pkg="$1"
    if [[ "$IS_BREW_OWNER" == true ]]; then
        brew install "$pkg"
    else
        if brew list "$pkg" &>/dev/null; then
            echo "✓ $pkg is available"
        else
            echo "⚠ $pkg not found — skipping (not Homebrew owner)"
        fi
    fi
}

echo "📦 Installing / verifying essential tools..."
verify_or_install git
verify_or_install openssh
verify_or_install rsync

# ───────────────────────────────────────────────
# 3. Setup GitHub SSH connection
# ───────────────────────────────────────────────

echo ""
echo "🔑 Step 1: GitHub SSH Setup"
bash "$SCRIPT_DIR/github-connect.sh"

# ───────────────────────────────────────────────
# 4. Clone macos-sync repo
# ───────────────────────────────────────────────

echo ""
echo "📥 Step 2: Deploying macos-sync to home"

REPO_SSH="git@github.com:DraconicAspirations/macos-sync.git"
SYNC_TMP="$HOME/macos-sync"

if [[ -d "$SYNC_TMP/.git" ]]; then
    echo "⚠ macos-sync already cloned at $SYNC_TMP"
    read -p "Re-clone from scratch? (y/n): " RECLONE
    if [[ "$RECLONE" =~ ^[Yy]$ ]]; then
        rm -rf "$SYNC_TMP"
        git clone "$REPO_SSH" "$SYNC_TMP"
    fi
else
    git clone "$REPO_SSH" "$SYNC_TMP"
fi

echo "📁 Deploying repo contents into $HOME (replacing existing files)..."
rsync -a "$SYNC_TMP/" "$HOME/"
rm -rf "$SYNC_TMP"
echo "✓ macos-sync deployed to home"

# ───────────────────────────────────────────────
# 5. Run setup
# ───────────────────────────────────────────────

echo ""
echo "🚀 Step 3: Running setup"

SETUP_SCRIPT="$HOME/bin/setup/setup.sh"
BREW_FLAG="--no-owner"
[[ "$IS_BREW_OWNER" == true ]] && BREW_FLAG="--owner"

if [[ -f "$SETUP_SCRIPT" ]]; then
    bash "$SETUP_SCRIPT" "$BREW_FLAG"
else
    echo "⚠ No setup script found at $SETUP_SCRIPT"
    echo "You may need to run it manually later"
fi

echo ""
echo "✅ Bootstrap Complete! $(date)"
echo "Restart your terminal for changes to take effect."


