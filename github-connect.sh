#!/usr/bin/env bash
set -e

sudo pacman -S --needed openssh

read -p "Enter your GitHub email: " EMAIL
read -p "Enter a name for the SSH key (default: id_ed25519): " KEYNAME
KEYNAME=${KEYNAME:-id_ed25519}
KEY="$HOME/.ssh/$KEYNAME"

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
