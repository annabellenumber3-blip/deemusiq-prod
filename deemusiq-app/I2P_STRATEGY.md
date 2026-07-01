# I2P Integration Strategy for DeeMusiq

## Overview

I2P (Invisible Internet Project) is an anonymous overlay network that can offload
backend responsibilities, improve privacy, and provide resilience. DeeMusiq can
use I2P for several backend tasks, reducing central server dependency.

## What I2P Provides

| Feature | How it helps DeeMusiq |
|---------|----------------------|
| **Garlic routing** | All traffic is encrypted end-to-end, relayed through multiple nodes — no single point knows both sender and receiver |
| **Hidden services** | Backend API can be exposed as an `.i2p` address, inaccessible from clearnet, immune to DDoS/takedown |
| **Peer-to-peer tunnels** | Users can share cached audio/metadata directly, reducing backend bandwidth |
| **Syndie-style forums** | Decentralized artist pages, comments, reviews — stored on I2P, not a server |
| **I2PSnark** | BitTorrent over I2P for distributing large catalogs, DRM-free audio, offline content packs |
| **Susimail** | Anonymous email for account recovery, notifications — no SMTP server needed |

## What Can Be Offloaded to I2P

### 1. Catalog Metadata Distribution (Priority: High)
Instead of every app hitting the central backend for `/metadata/*`, catalog
snapshots can be distributed over I2P:

```
Backend publishes catalog snapshot → I2P distributed hash table (DHT)
  → Seed nodes mirror → Apps fetch from nearest peer
  → Backend only handles delta updates (new tracks, edits)
```

**Implementation**: Use I2P's HTTP proxy to serve a static JSON catalog from
a hidden service. Apps fetch from `catalog.deemusiq.i2p` first, fall back to
clearnet backend. Delta updates via I2P Bote (email-like messaging).

**Bandwidth savings**: 90%+ reduction in backend requests.

### 2. Audio Source Caching (Priority: Medium)
YouTube extraction results (manifest URLs, stream info) can be cached in an
I2P DHT:
```
User A extracts track X from YouTube → caches manifest in I2P DHT
  → User B requests track X → checks I2P DHT first
  → If found: skips YouTube extraction entirely (saves quota, faster)
  → If not found or stale: extracts fresh, updates DHT
```

### 3. Payment Verification (Priority: Low)
Crypto payment confirmations can be relayed over I2P:
```
Backend confirms blockchain payment → publishes to I2P topic
  → App subscribes to topic → receives confirmation
  → Wallet credits without hitting clearnet backend
```

### 4. Leaderboard + Stats (Priority: Medium)
Leaderboard data is public and small — perfect for I2P distribution:
```
Backend publishes daily leaderboard snapshot → I2P DHT
  → Apps fetch from nearest peer → display offline
  → Push counts submitted via I2P, batched hourly
```

### 5. Anonymous Analytics (Priority: Low)
Usage stats (play counts, skips, likes) can be submitted anonymously:
```
App collects stats locally → anonymizes → submits via I2P tunnel
  → No IP address, no device fingerprint exposed
  → Backend aggregates for recommendations
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                  DeeMusiq App                     │
│  ┌──────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ YouTube  │  │ I2P      │  │ Clearnet      │  │
│  │ Audio    │  │ Client   │  │ Backend       │  │
│  │ (always) │  │ (proxy)  │  │ (fallback)    │  │
│  └──────────┘  └──────────┘  └───────────────┘  │
│       │              │               │           │
│       ▼              ▼               ▼           │
│  Audio plays    Catalog +       Payments +       │
│  regardless    Leaderboard     Purchases         │
│                + Stats         (auth required)   │
└─────────────────────────────────────────────────┘
```

## What MUST Stay on Clearnet Backend

- **Payment processing** (Stripe/PayFast/NOWPayments) — requires real-world banking
- **User authentication** (JWT, device attestation) — requires a trusted authority
- **Content moderation** — legal compliance (SA Films and Publications Act)
- **DMCA/copyright response** — legal requirement

## Implementation Plan

### Phase 1: I2P Catalog Mirror (now)
- Run a lightweight I2P hidden service on the backend server
- Serve static `/metadata` JSON snapshots over I2P
- App checks I2P first, falls back to clearnet

### Phase 2: I2P DHT for Audio Cache (soon)
- `i2p.snark` DHT for audio manifests
- Reduces YouTube quota usage by 60-80%

### Phase 3: Decentralized Leaderboard (later)
- Publish leaderboard via I2P DHT
- Batched push submissions over I2P tunnels

## Dependencies
- `i2pd` (C++ I2P router) — runs as daemon on backend server
- App uses I2P HTTP proxy (`localhost:4444`) — standard HTTP, no new Flutter deps
- Optional: `i2p.snark` for BitTorrent distribution
