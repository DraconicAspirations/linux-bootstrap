#!/usr/bin/env bash
set -euo pipefail

source ./pkg.sh

REPO_SSH="git@github.com:DraconicAspirations/unix-sync.git"
SYNC_DIR="$HOME/linux-sync"

pkg_install git rsync openssh

if [[ -d "$SYNC_DIR/.git" ]]; then
  echo "Existing linux-sync repo found. Pulling latest…"
  git -C "$SYNC_DIR" pull
else
  echo "Cloning repo: $REPO_SSH"
  [[ -d "$SYNC_DIR" ]] && rm -rf "$SYNC_DIR"
  git clone "$REPO_SSH" "$SYNC_DIR"
fi

echo "Syncing files into home directory…"

rsync -av \
  --exclude=".ssh/" \
  "$SYNC_DIR/" "$HOME/" || {
    code=$?

    # Exit code 24 = vanished source files, usually transient git lock files.
    if [[ $code -ne 24 ]]; then
      echo "❌ rsync failed with exit code $code"
      exit "$code"
    fi
  }

echo "✔ Sync complete!"
