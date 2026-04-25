#!/usr/bin/env bash
# Enable systemd services for a given surface
set -euo pipefail

SURFACE="${1:-base}"

# Services enabled on ALL surfaces
BASE_SERVICES=(
    "sorabbyngo-nodeid.service"
    "sorabbyngo-sentinel.service"
    "sorabbyngo-hardening.service"
)

# Surface-specific services
declare -A SURFACE_SERVICES
SURFACE_SERVICES["base"]=""
SURFACE_SERVICES["novela-os"]="novela.service novela-monitors.service"
SURFACE_SERVICES["sentinel-os"]="sorabbyngo-cyberwall.service byngo-agent.service byngo-net.service"
SURFACE_SERVICES["byngo-os"]="chameha.service byngox.service"
SURFACE_SERVICES["edge-os"]="sorabbyngo-edge.service byngonet.service"
SURFACE_SERVICES["server-os"]="byngox.service byngonet.service sorabbyngo-cyberwall.service"

enable_if_exists() {
    local svc="$1"
    if systemctl list-unit-files | grep -q "^${svc}"; then
        systemctl enable "$svc" 2>/dev/null && echo "Enabled: $svc" || echo "Warning: failed to enable $svc"
    else
        echo "Unit not found (skipping): $svc"
    fi
}

echo "Enabling base services..."
for svc in "${BASE_SERVICES[@]}"; do
    enable_if_exists "$svc"
done

echo "Enabling surface services for: $SURFACE"
IFS=' ' read -ra SURFACE_SVCS <<< "${SURFACE_SERVICES[$SURFACE]:-}"
for svc in "${SURFACE_SVCS[@]}"; do
    enable_if_exists "$svc"
done

echo "Service enablement complete"
