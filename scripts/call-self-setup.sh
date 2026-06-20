#!/usr/bin/env bash
set -euo pipefail

#!/usr/bin/env bash
set -euo pipefail

SELF_SETUP="$HOME/linux-sync/self-setup.sh"

if [[ ! -f "$SELF_SETUP" ]]; then
    echo "❌ self-setup.sh not found at $SELF_SETUP"
    echo "   Did sync-home.sh complete successfully?"
    exit 1
fi

if [[ ! -x "$SELF_SETUP" ]]; then
    chmod +x "$SELF_SETUP"
fi

echo "🏠 Running personal home setup…"
bash "$SELF_SETUP"