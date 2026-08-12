#!/usr/bin/env bash
set -e

source ./pkg.sh

build_ssh_name() {
    local user
    local host
    local public_ip
    local unique_id

    user="$(whoami)"

    if command -v hostname >/dev/null 2>&1; then
        host="$(hostname)"
    elif command -v hostnamectl >/dev/null 2>&1; then
        host="$(hostnamectl --static 2>/dev/null || true)"
    elif [[ -r /etc/hostname ]]; then
        host="$(cat /etc/hostname)"
    else
        host="unknown-host"
    fi

    if command -v curl >/dev/null 2>&1; then
        public_ip="$(curl -fsSL --max-time 5 https://api.ipify.org 2>/dev/null || true)"
    elif command -v wget >/dev/null 2>&1; then
        public_ip="$(wget -qO- --timeout=5 https://api.ipify.org 2>/dev/null || true)"
    else
        public_ip=""
    fi

    if [[ -z "$public_ip" ]]; then
        public_ip="unknown-ip"
    fi

    unique_id="$(
        {
            printf '%s\n' "$user"
            printf '%s\n' "$host"
            [[ -r /etc/machine-id ]] && cat /etc/machine-id
            [[ -r /var/lib/dbus/machine-id ]] && cat /var/lib/dbus/machine-id
        } | sha1sum | awk '{print substr($1, 1, 8)}'
    )"

    echo "${user}@${host} (${public_ip}) (${unique_id})"
}

pkg_install openssh

read -p "Enter a name for the SSH key (default: id_ed25519): " KEYNAME
KEYNAME=${KEYNAME:-id_ed25519}
KEY="$HOME/.ssh/$KEYNAME"

if [[ -f "$KEY" ]]; then
    echo "⚠️  SSH key already exists at: $KEY"
    read -p "Do you want to recreate it? This will overwrite the existing key. [y/N]: " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "✅ Skipping SSH key creation. Using existing key."

        if [[ -f "$KEY.pub" ]]; then
            echo ""
            echo "Your existing public key:"
            echo "--------------------------------"
            cat "$KEY.pub"
            echo "--------------------------------"
        fi

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
echo "To save this key in GitHub:"
echo ""
echo "1. Open Github"
echo "https://github.com/settings/ssh/new"
echo ""
echo "2. Give it the following name:"
echo "$(build_ssh_name)"
echo ""
echo "3. Enter the following key:"
cat "$KEY.pub"

read -r -p "Press Enter once the key is added to verify… " < /dev/tty

echo "Running verification... (ssh -T git@github.com)"
if ssh -T git@github.com; then
    :
else
    status=$?
    # GitHub returns exit status 1 after successful authentication because it
    # deliberately does not provide shell access. Treat that as success.
    if [[ $status -ne 1 ]]; then
        echo "❌ GitHub SSH verification failed with exit status $status"
        exit "$status"
    fi
fi

read -r -p "Verification complete. Press enter to proceed. " < /dev/tty
