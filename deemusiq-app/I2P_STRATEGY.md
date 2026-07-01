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

## Network Safety

### Rate Limits — Catalog Distribution

DeeMusiq MUST respect I2P network norms to avoid degrading the network for other users:

| Limit | Value | Rationale |
|-------|-------|-----------|
| **Catalog sync interval** | Once per 24 hours (not on every app open) | Prevents flooding the DHT; static snapshots don't need live refresh |
| **Per-peer bandwidth** | < 1 KB/s sustained for catalog distribution | I2P is a volunteer network; aggressive leeching hurts relay nodes |
| **Max catalog snapshot size** | 512 KB compressed JSON | Larger payloads belong on I2PSnark, not the DHT |
| **Delta update frequency** | At most 1 fetch per hour | Even delta updates should be batched |
| **Concurrent DHT lookups** | Max 4 simultaneous | Respects I2P router resource limits |

### DHT Etiquette

- **TTL on cached entries**: All catalog/leaderboard entries stored in the I2P DHT MUST have a TTL of 24 hours maximum. Stale entries poison the DHT and waste limited storage.
- **Size limits**: The I2P DHT has practical per-entry limits of ~1 KB. DeeMusiq MUST chunk catalog entries that exceed this and MUST NOT store audio data in the DHT.
- **Replication factor**: Do not force-replicate entries beyond I2P's default (typically 3–5 replicas). Over-replication is network abuse.
- **No DHT write amplification**: Never re-publish unchanged entries. Hash the content and compare before republishing.

### What DeeMusiq MUST NOT Do on I2P

| Prohibited Activity | Why |
|---------------------|-----|
| **Real-time audio streaming** | I2P latency is too high (500 ms–2 s typical); streaming would saturate tunnels and degrade the network |
| **Large file transfers (> 10 MB)** | Use I2PSnark (BitTorrent over I2P) for large payloads. The DHT and HTTP proxy are for metadata only |
| **Clearnet bridging / outproxy** | DeeMusiq must NEVER act as an I2P outproxy (no clearnet gateway). This is the #1 abuse vector on I2P and is banned by most I2P routers. DeeMusiq is a consumer of I2P, not a bridge |
| **Unthrottled background sync** | All I2P traffic must be user-initiated or on a conservative timer. No continuous background polling |
| **Sybil attacks / fake nodes** | Never run multiple I2P routers to artificially boost DeeMusiq's presence. One router per backend server is the limit |
| **I2P DHT as a general-purpose database** | The DHT is for discovery, not storage. Do not store user data, playlists, or payment info in the DHT |

### Device Bandwidth Contribution (Network Sustainment)

Every DeeMusiq installation that enables I2P MUST contribute relay bandwidth to the
network. This is the fundamental I2P social contract — you consume, you contribute.

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| **Minimum relay bandwidth** | 500 KB/s shared transit | Ensures the network has enough capacity for all DeeMusiq users |
| **Maximum relay bandwidth** | 700 KB/s shared transit | Prevents a single device from dominating or overheating |
| **Transit tunnel count** | 2–4 exploratory + 2–4 client tunnels | Standard I2P router configuration for a contributing peer |
| **Grace period** | First 5 minutes after app launch | Allows initial catalog sync before relay traffic begins |
| **Bandwidth throttle** | CPU-bound, not network-bound | I2P garlic encryption is CPU-intensive; ~700 KB/s is the practical ceiling on mobile/desktop |
| **User override** | Toggle in Settings → Network → "Contribute to I2P network" | Default ON. Users on metered connections or battery-constrained devices can disable relay while still consuming I2P services |
| **Impact on DeeMusiq traffic** | Negligible | DeeMusiq's own traffic (catalog sync, leaderboard) is < 5 KB/s. The 500–700 KB/s relay contribution is almost entirely other people's traffic passing through |

#### Why This Matters

```
Without relay contribution:
  DeeMusiq users = net consumers → I2P network degrades for everyone

With relay contribution:
  DeeMusiq users = net contributors → I2P network grows stronger
  → More capacity for catalog distribution
  → Better anonymity (more cover traffic)
  → Faster DHT lookups (more peers)
```

#### Implementation

```
App starts → I2P router inits → 5-min grace period
  → Catalog sync completes (DeeMusiq's own traffic: < 5 KB/s)
  → Relay tunnels open → begin accepting transit traffic
  → Throttle to 500–700 KB/s based on CPU temperature/usage
  → If CPU > 80% or battery < 20%: reduce to 200 KB/s minimum
  → If user disables: relay stops, catalog/leaderboard still work
```

### Architecture Constraints

```
Permitted (metadata only):
  App → I2P HTTP Proxy → Catalog Snapshot (GET, ≤ 1 KB/s, 1×/day)
  App → I2P DHT → Cached Audio Manifest (lookup only, TTL 24h)
  Backend → I2P DHT → Publish static snapshots (1×/day)

NOT Permitted:
  App → I2P → YouTube/clearnet (no bridging, ever)
  App → I2P → Real-time audio stream
  App → I2P → Large file download (> 10 MB)
  Backend → I2P → User authentication data
  Backend → I2P → Payment information
```

### Implementation Checklist

- [ ] Catalog fetch gated on a 24-hour cooldown timer (stored in SharedPreferences)
- [ ] HTTP client configured with per-second bandwidth throttle for I2P proxy requests
- [ ] DHT put operations include `expires=` header (24h max)
- [ ] Chunked catalog entries for payloads > 1 KB
- [ ] No SOCKS/outproxy configuration — HTTP proxy only, clearnet fallback is direct
- [ ] Log warning if any I2P operation exceeds 30 seconds (network health indicator)
- [ ] User-facing toggle: "Use I2P for catalog" — off by default, requires I2P router running locally

## Dependencies
- `i2pd` (C++ I2P router) — runs as daemon on backend server
- App uses I2P HTTP proxy (`localhost:4444`) — standard HTTP, no new Flutter deps
- Optional: `i2p.snark` for BitTorrent distribution
