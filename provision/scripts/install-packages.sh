#!/usr/bin/env bash
# Install packages from a profile file
# Lines starting with # are comments, blank lines are skipped
set -euo pipefail

PROFILE="$1"
[[ -f "$PROFILE" ]] || { echo "Profile not found: $PROFILE"; exit 1; }

# Detect package manager
if command -v apt-get &>/dev/null; then
    PKG_MGR="apt"
elif command -v dnf &>/dev/null; then
    PKG_MGR="dnf"
elif command -v pacman &>/dev/null; then
    PKG_MGR="pacman"
else
    echo "No supported package manager found"
    exit 1
fi

# Read packages
PACKAGES=()
while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    PACKAGES+=("$line")
done < "$PROFILE"

if [[ ${#PACKAGES[@]} -eq 0 ]]; then
    echo "No packages to install"
    exit 0
fi

echo "Installing ${#PACKAGES[@]} packages via $PKG_MGR..."

case "$PKG_MGR" in
    apt)
        apt-get update -qq
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            "${PACKAGES[@]}" 2>&1
        ;;
    dnf)
        dnf install -y "${PACKAGES[@]}" 2>&1
        ;;
    pacman)
        pacman -Sy --noconfirm "${PACKAGES[@]}" 2>&1
        ;;
esac

echo "Package installation complete"
