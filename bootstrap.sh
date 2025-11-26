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
# 1. System Update + Required Base Packages
# ───────────────────────────────────────────────

echo "🔧 Updating system and installing base tools..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git rsync openssh

# ───────────────────────────────────────────────
# 2. Ensure ~/.ssh Directory Exists
# ───────────────────────────────────────────────

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# ───────────────────────────────────────────────
# 3. SSH Key Setup (idempotent)
# ───────────────────────────────────────────────

DEFAULT_KEY="$HOME/.ssh/id_ed25519"
if [[ ! -f "$DEFAULT_KEY" ]]; then
    echo "🔑 No SSH key found. Creating a new one."

    read -p "Enter your GitHub email: " EMAIL
    EMAIL=${EMAIL:-""}
    if [[ -z "$EMAIL" ]]; then
        echo "❌ Email required to generate SSH key."
        exit 1
    fi

    ssh-keygen -t ed25519 -C "$EMAIL" -f "$DEFAULT_KEY" -N ""
    eval "$(ssh-agent -s)"
    ssh-add "$DEFAULT_KEY"

    echo ""
    echo "📋 Add this SSH key to GitHub:"
    echo "--------------------------------"
    cat "$DEFAULT_KEY.pub"
    echo "--------------------------------"
    echo ""
    read -p "Press enter after adding key to GitHub…" _
else
    echo "🔑 SSH key already exists; skipping generation."
    eval "$(ssh-agent -s)"
    ssh-add "$DEFAULT_KEY" || true
fi

# ───────────────────────────────────────────────
# 4. Clone `linux-sync` repo via SSH
# ───────────────────────────────────────────────

SYNC_DIR="$HOME/linux-sync"
REPO_SSH="git@github.com:DraconicAspirations/linux-sync.git"

echo "📥 Cloning sync repository…"
rm -rf "$SYNC_DIR"
git clone "$REPO_SSH" "$SYNC_DIR"

# ───────────────────────────────────────────────
# 5. Sync dotfiles to $HOME (idempotent)
# ───────────────────────────────────────────────

echo "📂 Syncing dotfiles into HOME…"
rsync -av \
    --exclude ".ssh/" \
    --exclude ".git/" \
    "$SYNC_DIR/" "$HOME/"

# ───────────────────────────────────────────────
# 6. Install packages listed in pkglist.txt
# ───────────────────────────────────────────────

PKGLIST="$HOME/linux-sync/pkglist.txt"

if [[ ! -f "$PKGLIST" ]]; then
    echo "⚠ No pkglist.txt found at $PKGLIST — skipping package install."
else
    echo "📦 Installing packages from pkglist.txt…"
    mapfile -t PACKAGES < <(grep -vE '^\s*$|^\s*#' "$PKGLIST")

    FAILED=()

    for pkg in "${PACKAGES[@]}"; do
        echo "→ Installing $pkg"
        if ! sudo pacman -S --needed --noconfirm "$pkg"; then
            echo "  ⚠ Failed to install: $pkg"
            FAILED+=("$pkg")
        fi
    done

    if (( ${#FAILED[@]} > 0 )); then
        echo ""
        echo "⚠ Failed packages:"
        printf "  - %s\n" "${FAILED[@]}"
    else
        echo "🎉 All packages installed."
    fi
fi

# ───────────────────────────────────────────────
# 7. Default Shell = Zsh (WSL-safe)
# ───────────────────────────────────────────────

echo "🐚 Installing Zsh…"
sudo pacman -S --needed --noconfirm zsh

if chsh -s /usr/bin/zsh "$USER" 2>/dev/null; then
    echo "✔ Default shell changed to zsh."
else
    echo "⚠ chsh failed (likely WSL). Adding fallback to ~/.profile"
    if ! grep -q 'exec zsh' "$HOME/.profile"; then
        echo 'exec zsh' >> "$HOME/.profile"
    fi
fi

echo ""
echo "=== Bootstrap Complete! ==="
echo "Restart your terminal."
