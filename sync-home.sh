#!/usr/bin/env bash
set -euo pipefail

REPO_SSH="git@github.com:DraconicAspirations/linux-sync.git"
SYNC_DIR="$HOME/linux-sync"

sudo pacman -S --needed git rsync openssh

# --- Clone repo ---
echo "Cloning repo: $REPO_SSH"
if [[ -d "$SYNC_DIR" ]]; then
  echo "Existing linux-sync folder found. Removing old version…"
  rm -rf "$SYNC_DIR"
fi

git clone "$REPO_SSH" "$SYNC_DIR"

# --- Sync files into home ---
echo "Syncing files into home directory…"

# Explanation:
# -a  = archive mode (keeps permissions, copies dirs/files)
# -v  = verbose
# --delete = delete removed files (optional, remove if you don't want this)
# --exclude = skip .git and sensitive directories
rsync -av \
  --exclude=".ssh/" \
  "$SYNC_DIR/" "$HOME/"

echo "✔ Sync complete!"
