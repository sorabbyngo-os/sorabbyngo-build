#!/usr/bin/env bash
# Build and install Sorabbyngo security tools (byngo-*)
set -euo pipefail

TOOLS_DIR="${1:-$HOME/sorabbyngo/malware-lab/tools}"
INSTALL_DIR="/usr/local/bin"

[[ -d "$TOOLS_DIR" ]] || { echo "Tools directory not found: $TOOLS_DIR"; exit 1; }

echo "Building Sorabbyngo security tools..."

cd "$TOOLS_DIR"

# Find cargo — check common locations
CARGO=""
for p in "$HOME/.cargo/bin/cargo" "/usr/local/bin/cargo" "$(which cargo 2>/dev/null)"; do
    [[ -x "$p" ]] && CARGO="$p" && break
done

if [[ -z "$CARGO" ]]; then
    echo "Rust/cargo not found — installing as current user..."
    su -c 'curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet' "${SUDO_USER:-$USER}"
    CARGO="/home/${SUDO_USER:-$USER}/.cargo/bin/cargo"
fi

echo "Using cargo: $CARGO"

# Build release as the calling user (not root)
if [[ -n "$SUDO_USER" ]]; then
    su "$SUDO_USER" -c "cd $TOOLS_DIR && $CARGO build --release" 2>&1
else
    "$CARGO" build --release 2>&1
fi

# Install binaries
for tool in byngo-static byngo-detect byngo-net byngo-agent; do
    if [[ -f "target/release/$tool" ]]; then
        install -m 755 "target/release/$tool" "$INSTALL_DIR/$tool"
        echo "Installed: $INSTALL_DIR/$tool"
    fi
done

echo "Sorabbyngo security tools installed"
