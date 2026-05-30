<p align="center">
  <img src="https://raw.githubusercontent.com/sorabbyngo-os/.github/main/assets/sorabbyngo-logo.jpg" width="480"/>
</p>
<p align="center">
  <strong>Sorabbyngo Build — Buildroot-based OS image pipeline</strong>
</p>

---

## What this is

This is the Buildroot tree that produces the Sorabbyngo OS image.
It builds a bootable ISO containing the full Sorabbyngo stack:
kernel, HAL, NATS, Byngox, Novela, Chameha, Cyberwall, Sentinel.

---

## Build Targets

| Target | Output | Use |
|---|---|---|
| `sorabbyngo_x86_64_defconfig` | x86_64 ISO + ext4 rootfs | Development, QEMU, x86 hardware |

---

## Quick Build

```bash
# Prerequisites
sudo apt-get install -y build-essential gcc g++ make git \
    libncurses-dev bison flex libssl-dev libelf-dev \
    python3 python3-pip wget cpio rsync bc

# Configure
make sorabbyngo_x86_64_defconfig

# Build (takes 30–90 min first time)
make -j$(nproc)

# Output
ls output/images/
# sorabbyngo.iso        ← bootable live ISO
# sorabbyngo-rootfs.ext4 ← root filesystem
```

---

## Boot in QEMU

```bash
qemu-system-x86_64 \
  -m 4G \
  -smp 4 \
  -cdrom output/images/sorabbyngo.iso \
  -boot d \
  -enable-kvm \
  -serial stdio \
  -net nic \
  -net user
```

---

## Boot Sequence
GRUB2
└── Linux 6.19.10-sorabbyngo
└── sorabbyngo-init (PID 1)
├── Stage 1: NodeID (sorabbyngo_nodeid.ko)
├── Stage 2: Network
├── Stage 3: NATS JetStream
├── Stage 4: Byngox (12-agent swarm)
├── Stage 4b: Cyberwall (AI firewall)
├── Stage 5: Novela (health platform)
├── Stage 6: Chameha (AI personality)
└── tty1: Chameha conversation loop
---

## Stack Versions

| Component | Version |
|---|---|
| Linux kernel | 6.19.10-sorabbyngo |
| Buildroot | 2024.02 |
| Python | 3.12 |
| NATS Server | 2.10.x |
| Ollama | latest |

---

**Sorabbyngo Company** · Kisii, Kenya · 2026
*Rhythm of Digital Life*
