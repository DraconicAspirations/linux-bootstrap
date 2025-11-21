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

FAILED_PACKAGES=()

echo "📦 Installing individual packages (won’t stop on errors)…"
# Temporarily disable exit-on-error
set +e

for pkg in $(grep -vE '^\s*$|^\s*#' "$PKGFILE"); do
    echo "→ Installing: $pkg"
    sudo pacman -S --needed --noconfirm "$pkg"
    if [[ $? -ne 0 ]]; then
        echo "  ⚠ Failed: $pkg"
        FAILED_PACKAGES+=("$pkg")
    fi
done

# Re-enable strict mode
set -e

echo "✔ Package install attempt completed."
echo ""

# --- Summary of failures ---
if (( ${#FAILED_PACKAGES[@]} > 0 )); then
    echo "⚠ The following packages failed to install:"
    for f in "${FAILED_PACKAGES[@]}"; do
        echo "   - $f"
    done
else
    echo "🎉 All packages installed successfully."
fi

echo ""

# --- Install zsh and set as default ---
echo "🐚 Installing and switching to zsh…"
sudo pacman -S --needed --noconfirm zsh

if chsh -s /usr/bin/zsh root 2>/dev/null; then
    echo "✔ Default shell changed to zsh system-wide."
else
    echo "⚠ chsh failed (WSL limitation). Falling back to user-level override."

    if ! grep -q 'exec zsh' ~/.profile; then
        echo 'exec zsh' >> ~/.profile
    fi

    echo "✔ Added zsh exec fallback to ~/.profile."
fi

echo ""
echo "🎉 Done! Restart your terminal."
