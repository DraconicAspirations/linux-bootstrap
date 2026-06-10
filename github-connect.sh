#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/pkg.sh"

pkg_install openssh

read -p "Enter a name for the SSH key (default: id_ed25519): " KEYNAME
KEYNAME=${KEYNAME:-id_ed25519}
KEY="$HOME/.ssh/$KEYNAME"

# Check if SSH key already exists
if [[ -f "$KEY" ]]; then
    echo "⚠️  SSH key already exists at: $KEY"
    read -p "Do you want to recreate it? This will overwrite the existing key. [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Skipping SSH key creation. Using existing key."
        
        # Still show the public key in case they need it
        if [[ -f "$KEY.pub" ]]; then
            echo ""
            echo "Your existing public key:"
            echo "--------------------------------"
            cat "$KEY.pub"
            echo "--------------------------------"
        fi
        
        # Try to add to ssh-agent if not already added
        eval "$(ssh-agent -s)" 2>/dev/null || true
        ssh-add "$KEY" 2>/dev/null || echo "Key may already be in ssh-agent"
        
        echo ""
        echo "You can verify your GitHub connection with:"
        echo "  ssh -T git@github.com"
        exit 0
    fi
    echo "🔄 Recreating SSH key..."
fi

read -p "Enter your GitHub email: " EMAIL
echo "Creating ssh key: $KEY"
ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""

eval "$(ssh-agent -s)"
ssh-add "$KEY"

echo ""
echo "Copy this public key to GitHub:"
echo "--------------------------------"
cat "$KEY.pub"
echo "--------------------------------"

echo "Then verify with:"
echo "  ssh -T git@github.com"
