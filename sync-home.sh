#!/usr/bin/env bash
set -euo pipefail

REPO_SSH="git@github.com:DraconicAspirations/linux-sync.git"
SYNC_DIR="$HOME/linux-sync"

sudo pacman -S --needed git rsync openssh

# --- Clone or update repo ---
if [[ -d "$SYNC_DIR/.git" ]]; then
  echo "Existing linux-sync repo found. Pulling latest…"
  git -C "$SYNC_DIR" pull
else
  echo "Cloning repo: $REPO_SSH"
  [[ -d "$SYNC_DIR" ]] && rm -rf "$SYNC_DIR"
  git clone "$REPO_SSH" "$SYNC_DIR"
fi

# --- Sync files into home ---
echo "Syncing files into home directory…"

# Explanation:
# -a  = archive mode (keeps permissions, copies dirs/files)
# -v  = verbose
# --delete = delete removed files (optional, remove if you don't want this)
# --exclude = skip .git and sensitive directories
rsync -av \
  --exclude=".ssh/" \
  "$SYNC_DIR/" "$HOME/" || {
    code=$?
    # Exit code 24 = vanished source files (transient git lock files). Safe to ignore.
    if [[ $code -ne 24 ]]; then
      echo "❌ rsync failed with exit code $code"
      exit $code
    fi
  }

echo "✔ Sync complete!"
