#!/usr/bin/env bash
set -euo pipefail

PKGFILE="$HOME/linux-sync/pkglist.txt"

# --- Validate pkglist.txt ---
if [[ ! -f "$PKGFILE" ]]; then
  echo "❌ pkglist.txt not found at $PKGFILE"
  exit 1
fi

# --- Install packages ---
echo "📦 Installing packages from $PKGFILE…"
sudo pacman -Syu --needed --noconfirm
sudo pacman -S --needed --noconfirm $(grep -vE '^\s*$|^\s*#' "$PKGFILE")

echo "✔ Packages installed."

# --- Install zsh and set as default ---
echo "🐚 Installing and switching to zsh…"
sudo pacman -S --needed --noconfirm zsh

# WSL note:
# chsh works on WSL as long as /etc/passwd exists normally.
# If it fails, we fall back to setting SHELL in ~/.profile
if chsh -s /usr/bin/zsh root 2>/dev/null; then
    echo "✔ Default shell changed to zsh system-wide."
else
    echo "⚠ chsh failed (WSL limitation). Falling back to user-level override."

    # Add fallback to ~/.bashrc or ~/.profile
    if ! grep -q 'exec zsh' ~/.profile; then
        echo 'exec zsh' >> ~/.profile
    fi

    echo "✔ Added zsh exec fallback to ~/.profile."
fi

echo ""
echo "🎉 Done! Restart your terminal."
