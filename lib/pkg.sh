#!/usr/bin/env bash
# Shared package manager helpers — sourced by all bootstrap scripts.
# Sets PKG_MANAGER if not already exported, then exposes pkg_install and pkg_update.

if [[ -z "${PKG_MANAGER:-}" ]]; then
    _distro_id=""
    if [[ -f /etc/os-release ]]; then
        _distro_id=$(. /etc/os-release && echo "${ID:-}")
    fi
    case "$_distro_id" in
        arch|manjaro|endeavouros) PKG_MANAGER="pacman" ;;
        fedora|rhel|centos)       PKG_MANAGER="dnf" ;;
        ubuntu|debian|pop|mint)   PKG_MANAGER="apt" ;;
        *)
            if command -v dnf >/dev/null 2>&1; then
                PKG_MANAGER="dnf"
            elif command -v apt-get >/dev/null 2>&1; then
                PKG_MANAGER="apt"
            elif command -v pacman >/dev/null 2>&1; then
                PKG_MANAGER="pacman"
            else
                echo "❌ No supported package manager found (pacman, dnf, apt-get)" >&2
                exit 1
            fi
            ;;
    esac
    echo "📦 Detected package manager: $PKG_MANAGER"
fi

pkg_install() {
    case "$PKG_MANAGER" in
        pacman) sudo pacman -S --needed --noconfirm "$@" ;;
        dnf)    sudo dnf install -y "$@" ;;
        apt)    sudo apt-get install -y "$@" ;;
    esac
}

pkg_update() {
    case "$PKG_MANAGER" in
        pacman) sudo pacman -Syu --noconfirm ;;
        dnf)    sudo dnf upgrade -y ;;
        apt)    sudo apt-get update && sudo apt-get upgrade -y ;;
    esac
}
