#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/pkg.sh"

PKGFILE="$HOME/linux-sync/.config/packages/pkglist.txt"

# --- Validate pkglist.txt ---
if [[ ! -f "$PKGFILE" ]]; then
  echo "❌ pkglist.txt not found at $PKGFILE"
  exit 1
fi

# --- Install packages ---
echo "📦 Installing packages from $PKGFILE…"
pkg_update

FAILED_PACKAGES=()

echo "📦 Installing individual packages (won’t stop on errors)…"
# Temporarily disable exit-on-error
set +e

for pkg in $(grep -vE '^\s*$|^\s*#' "$PKGFILE"); do
    echo "→ Installing: $pkg"
    pkg_install "$pkg"
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
pkg_install zsh

ZSH_PATH="$(command -v zsh)"
if sudo chsh -s "$ZSH_PATH" "$USER"; then
    echo "✔ Default shell changed to zsh for user $USER."
else
    echo "⚠ chsh failed (WSL limitation). Falling back to user-level override."

    if ! grep -q 'exec zsh' ~/.profile; then
        echo 'exec zsh' >> ~/.profile
    fi

    echo "✔ Added zsh exec fallback to ~/.profile."
fi

echo ""
echo "🎉 Done! Shell setup complete."
