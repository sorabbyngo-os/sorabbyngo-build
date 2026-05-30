# SORABBYNGO - Internal Architecture Blueprint

This is the definitive engineering map. Each section is a separate private repo with controlled access. Do NOT implement as a single monorepo - security boundaries require repo separation.

**Version:** 2.0 | **Date:** 2026-04-04 | CONFIDENTIAL

## Repository Map

| Folder | Repo | Access |
|---|---|---|
| prime/ | odolocharles/prime | Founder only |
| dmz/ | odolocharles/sorabbyngo-dmz | Founder only |
| os/kernel/ | odolocharles/linux-sorabbyngo | Founder only |
| os/ | sorabbyngo-os/sorabbyngo-os | Core team |
| byngonet/ | sorabbyngo-os/byngonet | Core team |
| os/byngox/ | sorabbyngo-os/byngox | Core team |
| os/chameha/ | sorabbyngo-os/chameha | Core team |
| cml/ | sorabbyngo-os/cml | Core team |
| novela/ | novela-health/novela | Core team |

## Full Architecture



## Security Boundaries

NEVER put in org repos: PRIME training code, DMZ service, Vault root keys, training datasets.

Founder only (odolocharles/): prime, sorabbyngo-dmz, linux-sorabbyngo

Core team (sorabbyngo-os/): all other repos

## Key ADRs
- ADR-001: Graphical Chameha boot, TTY fallback F2-F6
- ADR-002: Novela hybrid - on-device core, optional remote
- ADR-003: Tiered AI - never broken, only less powerful
- ADR-004: NATS over Kafka
- ADR-005: safetensors + Ed25519 for PRIME artifacts
- ADR-006: Repo separation over monorepo for security

Sorabbyngo Company - Kisii, Kenya | 2026 | CONFIDENTIAL
