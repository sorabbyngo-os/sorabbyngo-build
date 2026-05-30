# ADR-004 — Sorabbyngo Kernel Ecosystem Strategy
**Status:** Accepted  
**Date:** 2026-04-21  
**Deciders:** Charles Odolo (Founder & CEO)

## Decision
**One sovereign AI kernel. Multiple specialized OS surfaces.**

The Sorabbyngo AI Kernel serves as the root base for all operating systems
built within the Sorabbyngo ecosystem. Each OS surface is a specialized
configuration of the same kernel — not a separate kernel fork.

---

## Context

Modern computing ecosystems that achieve security, manageability, and
scale share a common architectural pattern: one kernel, many surfaces.

| Ecosystem | Root Kernel | OS Surfaces |
|---|---|---|
| Apple | Darwin (XNU) | macOS, iOS, watchOS, tvOS, visionOS |
| Google | Linux | Android, ChromeOS, Wear OS, Fuchsia |
| Microsoft | Windows NT | Windows, Xbox OS, HoloLens OS |
| **Sorabbyngo** | **Sorabbyngo AI Kernel** | **Novela OS, Sentinel OS, Byngo OS, Edge OS, Server OS** |

A single-kernel approach means:
- One security patch propagates across the entire ecosystem
- Byngonet identity layer works natively on every device
- SUID identity system spans all surfaces
- AI cognitive layer (Byngox + Chameha) runs consistently
- Kenya Data Protection Act compliance enforced at kernel level

---

## The Ecosystem
SORABBYNGO AI KERNEL (Linux 6.19.10-sorabbyngo)
│
├── Novela OS          — Medical and clinical equipment
│   Target: hospitals, clinics, CHW devices, diagnostic equipment
│   Key requirement: PREEMPT_RT real-time patches
│
├── Sentinel OS        — Cybersecurity operations
│   Target: security operations centers, penetration testing, threat analysis
│   Key requirement: network isolation, forensic tooling, hardened kernel
│
├── Byngo OS           — Consumer devices
│   Target: phones, tablets, laptops, earbuds, smartwatches
│   Key requirement: Android runtime compatibility, battery optimization
│
├── Edge OS            — Embedded and IoT
│   Target: drones, vehicles, smart city nodes, sensors, robotics
│   Key requirement: minimal footprint, real-time control, CAN bus support
│
└── Server OS          — Infrastructure
Target: hospital servers, Byngonet regional nodes, data centers
Key requirement: high availability, vLLM inference, NATS clustering

---

## Architecture Principle

### Common Base — Specialized Configs
All OS surfaces share:
- The same kernel source tree (`sorabbyngo-os/sorabbyngo-os`)
- The same Byngonet kernel modules
- The same NodeID hardware identity driver
- The same AI supervisor layer
- The same post-quantum cryptography stack

Each OS surface has its own:
- Kernel defconfig (build-time specialization)
- Root filesystem (different packages per surface)
- systemd target (different boot sequence)
- AI model tier (different model sizes)
sorabbyngo-os/configs/
├── sorabbyngo_x86_64_defconfig        ← Base / development
├── sorabbyngo_medical_defconfig       ← Novela OS (PREEMPT_RT)
├── sorabbyngo_sentinel_defconfig      ← Sentinel OS (hardened)
├── sorabbyngo_consumer_defconfig      ← Byngo OS (Android compat)
├── sorabbyngo_edge_arm_defconfig      ← Edge OS (ARM, minimal)
└── sorabbyngo_server_defconfig        ← Server OS (throughput)
---

## Security Advantages

### Single Patch Surface
A CVE patched in the Sorabbyngo kernel is patched across every device
in the ecosystem simultaneously — phones, hospital equipment, drones,
and city nodes all benefit from one fix.

### Unified Identity
Every device running any Sorabbyngo OS surface has a hardware-bound
NodeID. The Byngonet network knows exactly which devices are trusted,
regardless of which OS surface they run.

### Audit Trail Continuity
CML audit logs, SUID-linked events, and Byngonet packet logs are
consistent across all surfaces. A forensic investigation can trace
an event from a clinical device through the hospital server to the
regional Byngonet node — all using the same identity primitives.

### Compliance at Kernel Level
Kenya Data Protection Act enforcement, access control policies, and
encryption requirements are implemented in the kernel — not in
application code. Application developers cannot bypass them.

---

## Specialized Requirements Per Surface

### Novela OS — Medical
- `PREEMPT_RT` patches — deterministic response under 1ms
- Stripped kernel — no unnecessary drivers or modules
- IEC 62443 industrial security baseline
- KEBS and Kenya PPB regulatory alignment
- Certified boot chain — no unsigned kernel modules

### Sentinel OS — Cybersecurity
- Hardened kernel (`CONFIG_HARDENED_USERCOPY`, `CONFIG_FORTIFY_SOURCE`)
- Network namespace isolation
- eBPF for real-time threat detection
- Forensic memory acquisition support
- Air-gap capable — Byngonet mesh without internet

### Byngo OS — Consumer
- Android Runtime (ART) compatibility layer
- Power management optimization (battery-first scheduling)
- GPU driver support (Mali, Adreno, PowerVR)
- Chameha voice boot — Wayland compositor
- 40+ African language NLP at kernel-adjacent layer

### Edge OS — IoT and Drones
- Minimal footprint — target under 50MB rootfs
- CAN bus support (vehicles)
- MAVLink protocol support (drones)
- TinyLLM / QLoRA compressed models for inference
- Watchdog and hardware failsafe integration

### Server OS — Infrastructure
- High-throughput network stack (XDP, io_uring)
- vLLM inference server integration
- NATS JetStream clustering
- ZFS or Btrfs for data integrity
- IPMI and out-of-band management

---

## Phased Implementation

| Phase | Milestone | Status |
|---|---|---|
| 1 | Single kernel + base OS (x86_64) | ✅ Complete |
| 2 | Specialized defconfigs per surface | 🔜 Next |
| 3 | Novela OS image (medical, PREEMPT_RT) | 🔜 Planned |
| 4 | Byngo OS image (consumer, Android compat) | 🔜 Planned |
| 5 | Edge OS image (ARM, minimal) | 🔜 Planned |
| 6 | Sentinel OS image (hardened) | 🔜 Planned |
| 7 | Server OS image (infrastructure) | 🔜 Planned |
| 8 | Unified build system — all surfaces from one pipeline | 🔜 Planned |

---

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Medical certification invalidated by consumer OS vulnerability | Strict config separation — medical defconfig excludes all non-clinical drivers |
| Real-time guarantees broken by AI supervisor overhead | PREEMPT_RT + AI supervisor runs in isolated cgroup with CPU pinning |
| Edge OS kernel too large for embedded targets | Separate minimal defconfig — strip to under 50MB |
| Drone/vehicle safety-critical failures | Formal verification of actuator control kernel modules before shipping |
| Android compatibility breaks on kernel updates | Maintain AOSP LTS-compatible patch set as separate branch |

---

## Consequences

- `sorabbyngo-os` repo becomes the single source of truth for all kernel development
- New repos created per OS surface: `novela-os`, `sentinel-os`, `byngo-os`, `edge-os`, `server-os`
- Each OS surface repo contains only: defconfig, rootfs overlay, systemd units, and surface-specific docs
- All kernel patches go through `sorabbyngo-os` — never directly into surface repos
- `sorabbyngo-build` tracks build status and phase completion for all surfaces
- Byngonet identity works identically across all surfaces — no surface-specific identity code

---

## Related ADRs
- ADR-001 — Boot Target (Chameha graphical boot)
- ADR-002 — Novela Deployment Model
- ADR-003 — AI Offline Strategy

---

*This decision establishes Sorabbyngo as a platform company,*  
*not a single-product company.*
