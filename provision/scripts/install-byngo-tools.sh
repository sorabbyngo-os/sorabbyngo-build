#!/usr/bin/env bash
# Build and install Sorabbyngo security tools (byngo-*)
set -euo pipefail

TOOLS_DIR="${1:-$HOME/sorabbyngo/malware-lab/tools}"
INSTALL_DIR="/usr/local/bin"

[[ -d "$TOOLS_DIR" ]] || { echo "Tools directory not found: $TOOLS_DIR"; exit 1; }

echo "Building Sorabbyngo security tools..."

cd "$TOOLS_DIR"

# Source cargo env if needed
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

command -v cargo &>/dev/null || { echo "Rust/cargo not found — installing..."; \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet; \
    source "$HOME/.cargo/env"; }

# Build release
cargo build --release 2>&1

# Install binaries
for tool in byngo-static byngo-detect byngo-net byngo-agent; do
    if [[ -f "target/release/$tool" ]]; then
        install -m 755 "target/release/$tool" "$INSTALL_DIR/$tool"
        echo "Installed: $INSTALL_DIR/$tool"
    fi
done

echo "Sorabbyngo security tools installed"
