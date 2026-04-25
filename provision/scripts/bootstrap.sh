#!/usr/bin/env bash
# ============================================================
# Sorabbyngo Machine Bootstrap
# Provisions any machine to run a Sorabbyngo OS surface.
#
# Usage: ./bootstrap.sh --surface <surface> --env <env> [--arch <arch>]
#
# Surfaces: base | novela-os | sentinel-os | byngo-os | edge-os | server-os
# Envs:     dev | lab | staging | prod | sandbox
# Arches:   x86_64 | arm64 | riscv64
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROVISION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PROVISION_DIR/.." && pwd)"
LOG_DIR="/var/log/sorabbyngo"
LOG_FILE="$LOG_DIR/bootstrap.log"
VERSION="0.1.0"

# Defaults
SURFACE="base"
ENV="dev"
ARCH="x86_64"
DRY_RUN=false
SKIP_PACKAGES=false
SKIP_HARDENING=false
SKIP_SYSTEMD=false

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   Sorabbyngo Machine Bootstrap v${VERSION}                   ║"
    echo "║   Rhythm of Digital Life · Kisii, Kenya                 ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log()  { echo -e "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ${GREEN}INFO${NC}  $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ${YELLOW}WARN${NC}  $*" | tee -a "$LOG_FILE"; }
err()  { echo -e "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] ${RED}ERROR${NC} $*" | tee -a "$LOG_FILE"; exit 1; }
step() { echo -e "\n${BOLD}── $* ${NC}"; }

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --surface <surface>   OS surface (base|novela-os|sentinel-os|byngo-os|edge-os|server-os)"
    echo "  --env <env>           Environment (dev|lab|staging|prod|sandbox)"
    echo "  --arch <arch>         Architecture (x86_64|arm64|riscv64)"
    echo "  --dry-run             Show what would be done without doing it"
    echo "  --skip-packages       Skip package installation"
    echo "  --skip-hardening      Skip hardening layer"
    echo "  --skip-systemd        Skip systemd service installation"
    echo "  -h, --help            Show this help"
    exit 0
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --surface) SURFACE="$2"; shift 2 ;;
            --env)     ENV="$2";     shift 2 ;;
            --arch)    ARCH="$2";    shift 2 ;;
            --dry-run) DRY_RUN=true; shift ;;
            --skip-packages)  SKIP_PACKAGES=true;  shift ;;
            --skip-hardening) SKIP_HARDENING=true; shift ;;
            --skip-systemd)   SKIP_SYSTEMD=true;   shift ;;
            -h|--help) usage ;;
            *) err "Unknown option: $1" ;;
        esac
    done
}

validate_args() {
    case "$SURFACE" in
        base|novela-os|sentinel-os|byngo-os|edge-os|server-os) ;;
        *) err "Invalid surface: $SURFACE" ;;
    esac
    case "$ENV" in
        dev|lab|staging|prod|sandbox) ;;
        *) err "Invalid environment: $ENV" ;;
    esac
    case "$ARCH" in
        x86_64|arm64|riscv64) ;;
        *) err "Invalid architecture: $ARCH" ;;
    esac
}

check_root() {
    if [[ $EUID -ne 0 && "$DRY_RUN" == "false" ]]; then
        err "Bootstrap must run as root (or use --dry-run)"
    fi
}

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} $*"
    else
        eval "$@"
    fi
}

# ---- Phase 1: System check ----
phase_check() {
    step "Phase 1: System check"

    log "Kernel: $(uname -r)"
    log "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')"
    log "Arch: $(uname -m)"
    log "RAM: $(free -h | awk '/^Mem:/{print $2}')"
    log "Disk: $(df -h / | awk 'NR==2{print $4}') available"

    # Check minimum requirements
    RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    if [[ $RAM_KB -lt 3145728 ]]; then  # 3GB minimum
        warn "RAM below recommended 4GB minimum (${RAM_KB}KB available)"
    fi

    mkdir -p "$LOG_DIR"
    log "Bootstrap starting — surface=$SURFACE env=$ENV arch=$ARCH"
}

# ---- Phase 2: Base packages ----
phase_packages() {
    step "Phase 2: Installing packages for surface: $SURFACE"
    [[ "$SKIP_PACKAGES" == "true" ]] && { warn "Skipping packages"; return; }

    local profile="$PROVISION_DIR/profiles/$SURFACE/packages.txt"
    local base_profile="$PROVISION_DIR/profiles/base/packages.txt"

    # Install base packages first
    if [[ -f "$base_profile" ]]; then
        log "Installing base packages..."
        run bash "$PROVISION_DIR/scripts/install-packages.sh" "$base_profile"
    fi

    # Install surface-specific packages
    if [[ -f "$profile" ]]; then
        log "Installing $SURFACE packages..."
        run bash "$PROVISION_DIR/scripts/install-packages.sh" "$profile"
    else
        warn "No package profile for surface: $SURFACE"
    fi
}

# ---- Phase 3: Sorabbyngo internal packages ----
phase_internal_packages() {
    step "Phase 3: Installing Sorabbyngo internal packages"

    local os_repo="$REPO_ROOT/../sorabbyngo-os"

    # Python package
    if [[ -d "$os_repo/packages/python/sorabbyngo_core" ]]; then
        log "Installing sorabbyngo_core Python package..."
        run pip install -e "$os_repo/packages/python/" \
            --break-system-packages --quiet
    else
        warn "sorabbyngo_core not found at $os_repo"
    fi

    # Rust tools (byngo-*)
    local malware_lab="$REPO_ROOT/../malware-lab/tools"
    if [[ -d "$malware_lab" ]]; then
        log "Installing Sorabbyngo security tools..."
        run bash "$PROVISION_DIR/scripts/install-byngo-tools.sh" "$malware_lab"
    fi
}

# ---- Phase 4: Hardening ----
phase_hardening() {
    step "Phase 4: Applying hardening for env: $ENV"
    [[ "$SKIP_HARDENING" == "true" ]] && { warn "Skipping hardening"; return; }

    local os_repo="$REPO_ROOT/../sorabbyngo-os"
    local hardening_script="$os_repo/hardening/install-hardening.sh"

    if [[ -f "$hardening_script" ]]; then
        run bash "$hardening_script" "$ENV"
    else
        warn "Hardening script not found"
    fi
}

# ---- Phase 5: NodeID ----
phase_nodeid() {
    step "Phase 5: NodeID provisioning"

    local nodeid_dir="/var/lib/sorabbyngo"
    local nodeid_file="$nodeid_dir/nodeid"

    if [[ -f "$nodeid_file" ]]; then
        log "NodeID already sealed: $(cat "$nodeid_file" | head -c 16)..."
        return
    fi

    log "Generating NodeID for this machine..."
    run mkdir -p "$nodeid_dir"

    # Generate from hardware characteristics
    local hw_hash
    hw_hash=$(cat /sys/class/dmi/id/product_uuid 2>/dev/null || \
              cat /etc/machine-id 2>/dev/null || \
              hostname | sha256sum | cut -c1-32)

    local nodeid
    nodeid=$(echo "${hw_hash}-${SURFACE}-$(date +%s)" | sha256sum | cut -c1-64)

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "  [DRY-RUN] Would write NodeID to $nodeid_file"
    else
        echo "$nodeid" > "$nodeid_file"
    fi
    log "NodeID sealed: ${nodeid:0:16}..."
}

# ---- Phase 6: Systemd services ----
phase_systemd() {
    step "Phase 6: Installing systemd services"
    [[ "$SKIP_SYSTEMD" == "true" ]] && { warn "Skipping systemd"; return; }

    local units_dir="$PROVISION_DIR/systemd"
    local surface_units="$units_dir/$SURFACE"

    # Install base units
    for unit in "$units_dir"/base/*.service "$units_dir"/base/*.timer; do
        [[ -f "$unit" ]] || continue
        log "Installing unit: $(basename "$unit")"
        run cp "$unit" /etc/systemd/system/
    done

    # Install surface-specific units
    if [[ -d "$surface_units" ]]; then
        for unit in "$surface_units"/*.service "$surface_units"/*.timer; do
            [[ -f "$unit" ]] || continue
            log "Installing unit: $(basename "$unit")"
            run cp "$unit" /etc/systemd/system/
        done
    fi

    run systemctl daemon-reload
    run bash "$PROVISION_DIR/scripts/enable-services.sh" "$SURFACE"
}

# ---- Phase 7: Environment config ----
phase_env_config() {
    step "Phase 7: Writing environment configuration"

    run mkdir -p /etc/sorabbyngo

    cat > /tmp/sorabbyngo-env << ENVEOF
# Sorabbyngo OS Environment Configuration
# Generated by bootstrap.sh on $(date -u +%Y-%m-%dT%H:%M:%SZ)
SORABBYNGO_ENV=$ENV
SORABBYNGO_SURFACE=$SURFACE
SORABBYNGO_ARCH=$ARCH
SORABBYNGO_VERSION=$VERSION
SORABBYNGO_NODE_ID=$(cat /var/lib/sorabbyngo/nodeid 2>/dev/null || echo "pending")
ENVEOF

    if [[ "$DRY_RUN" != "true" ]]; then cp /tmp/sorabbyngo-env /etc/sorabbyngo/environment; fi
    if [[ "$DRY_RUN" != "true" ]]; then
    echo "source /etc/sorabbyngo/environment" >> /etc/profile.d/sorabbyngo.sh
    fi
    log "Environment config written to /etc/sorabbyngo/environment"
}

# ---- Phase 8: Verification ----
phase_verify() {
    step "Phase 8: Verification"

    local ok=true

    # Check NodeID
    if [[ -f /var/lib/sorabbyngo/nodeid ]]; then
        log "✓ NodeID: $(cat /var/lib/sorabbyngo/nodeid | head -c 16)..."
    else
        warn "✗ NodeID not found"
        ok=false
    fi

    # Check Python package
    if python3 -c "import sorabbyngo_core" 2>/dev/null; then
        log "✓ sorabbyngo_core Python package"
    else
        warn "✗ sorabbyngo_core not importable"
    fi

    # Check environment config
    if [[ -f /etc/sorabbyngo/environment ]]; then
        log "✓ Environment config"
    else
        warn "✗ Environment config missing"
    fi

    # Check systemd units
    if systemctl list-unit-files | grep -q "sorabbyngo"; then
        log "✓ Systemd units installed"
    else
        warn "✗ No Sorabbyngo systemd units found"
    fi

    if [[ "$ok" == "true" ]]; then
        log "Bootstrap verification: PASSED"
    else
        warn "Bootstrap verification: PARTIAL — check warnings above"
    fi
}

# ---- Summary ----
phase_summary() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║   Bootstrap Complete                                     ║"
    echo "╠══════════════════════════════════════════════════════════╣"
    printf "║   Surface  : %-43s║\n" "$SURFACE"
    printf "║   Env      : %-43s║\n" "$ENV"
    printf "║   Arch     : %-43s║\n" "$ARCH"
    printf "║   NodeID   : %-43s║\n" "$(cat /var/lib/sorabbyngo/nodeid 2>/dev/null | head -c 16)..."
    printf "║   Log      : %-43s║\n" "$LOG_FILE"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ---- Main ----
main() {
    parse_args "$@"
    validate_args
    check_root
    banner
    phase_check
    phase_packages
    phase_internal_packages
    phase_hardening
    phase_nodeid
    phase_systemd
    phase_env_config
    phase_verify
    phase_summary
}

main "$@"
