# Rate Limiting Audit — DeeMusiq App (Client-Side)

**Date**: 2026-07-01
**Auditor**: Agent 2 (I2P safety + rate limits + input sanitization)
**Scope**: `deemusiq-app/lib/` — all client-side rate limiting, caching, and API call throttling

> **Note**: The DeeMusiq backend (`s-b-repo/deemusiq-backend`) is NOT in this workspace. The CHANGELOG documents that the backend has rate limiting on `/auth/*` endpoints, env-configurable rate limits, and rate limiting on `/integrity/report`. This audit covers the **Flutter client side only** — whether the app itself throttles its own calls to avoid hammering the backend or external APIs.

---

## 1. Auth Endpoints — No Client-Side Rate Limiting

**File**: `lib/services/wallet/wallet_api.dart`

Every auth method calls the backend with zero client-side throttling:

| Line(s) | Method | Endpoint | Severity | Fix |
|---------|--------|----------|----------|-----|
| 143–181 | `_authToken()` | `POST /auth/device/challenge` → `POST /auth/device/login` | **HIGH** | Add debounce (min 500ms between calls); cache challenge nonce to avoid re-requesting within 60s |
| 184–197 | `registerEmail()` | `POST /auth/register` | **HIGH** | Add cooldown (1 call per 5s); button must disable during flight |
| 200–213 | `loginEmail()` | `POST /auth/login` | **HIGH** | Add cooldown (1 call per 3s); button must disable during flight |
| 252–258 | `requestVerify()` | `POST /auth/request-verify` | **MEDIUM** | Cooldown 60s between resends |
| 262–268 | `forgotPassword()` | `POST /auth/forgot-password` | **MEDIUM** | Cooldown 60s between requests |
| 414–430 | `authWithGoogle()` | `POST /auth/google` | **MEDIUM** | Cooldown 3s |

**Risk**: A user with a stuck button or rapid tapping could fire 10+ auth requests per second. While the backend has server-side rate limiting (per CHANGELOG), the app should not rely on the backend to absorb this — it wastes server resources and risks the client getting IP-banned.

**Fix pattern**:
```dart
DateTime? _lastAuthAttempt;
Future<void> _guardAuth(Future<void> Function() fn) async {
  if (_lastAuthAttempt != null &&
      DateTime.now().difference(_lastAuthAttempt!) < const Duration(seconds: 3)) {
    throw WalletApiException('Please wait before trying again');
  }
  _lastAuthAttempt = DateTime.now();
  await fn();
}
```

---

## 2. Catalog Write Endpoints (Admin) — No Rate Limiting

**File**: `lib/services/wallet/wallet_api.dart`

| Line(s) | Method | Endpoint | Severity | Fix |
|---------|--------|----------|----------|-----|
| 475–488 | `syncCreatePlaylist()` | `POST /sync/playlists` | **MEDIUM** | Rate limit to 5 creates/minute |
| 492–509 | `syncUpdatePlaylist()` | `PATCH /sync/playlists/:id` | **MEDIUM** | Rate limit to 10 updates/minute |
| 512–521 | `syncDeletePlaylist()` | `DELETE /sync/playlists/:id` | **MEDIUM** | Rate limit to 10 deletes/minute |

**Risk**: These are user-facing playlist operations, not true admin endpoints. However, rapid playlist creation/deletion cycles could cause backend DB churn. The backend should enforce, but the client should also debounce.

---

## 3. Wallet/Payment Endpoints — No Rate Limiting

**File**: `lib/services/wallet/wallet_api.dart`

| Line(s) | Method | Endpoint | Severity | Fix |
|---------|--------|----------|----------|-----|
| 325–340 | `createCheckout()` | `POST /payments/checkout` | **HIGH** | One active checkout per user; button disable during flight; 10s cooldown |
| 353–379 | `pushSong()` | `POST /wallet/push` | **HIGH** | Max 1 push per 3s per track; debounce UI |
| 382–397 | `supportCreator()` | `POST /wallet/support` | **HIGH** | Max 1 support per 3s per creator |
| 344–351 | `fetchWallet()` | `GET /wallet` | **MEDIUM** | Cache for 30s; don't re-fetch on every tab switch |

**Risk**: `pushSong()` and `supportCreator()` spend tokens from the user's balance. Rapid calls could cause ledger race conditions or double-spends if the backend doesn't use transaction isolation. The client must gate these.

---

## 4. Leaderboard / Recommendations — No Caching

**File**: `lib/services/wallet/wallet_api.dart` + `lib/provider/recommendations/for_you.dart`

| File:Line | Issue | Severity | Fix |
|-----------|-------|----------|-----|
| `wallet_api.dart:539–546` | `fetchLeaderboard()` — no caching, called on every UI render | **MEDIUM** | Cache for 5 minutes; leaderboard is public and doesn't change second-to-second |
| `wallet_api.dart:580–590` | `fetchRecommendations()` — no caching, refetched on every `load()` | **HIGH** | Cache for 1 hour; recommendations are expensive to generate (ML pipeline per CHANGELOG) |
| `for_you.dart:105–134` | `RecommendationsNotifier.load()` — fires on provider creation, no backoff | **HIGH** | Add stale-while-revalidate pattern; don't re-fetch if last fetch < 30 min ago |
| `for_you.dart:136–162` | `refresh()` — user can spam refresh | **MEDIUM** | Cooldown 60s between refreshes |

**Evidence from code**:
```dart
// for_you.dart:105-134 — no cache check before fetch
Future<void> load() async {
    if (!_isConfigured) { ... }
    state = state.copyWith(isLoading: true, error: null);
    final data = await WalletApiClient.instance.fetchRecommendations(); // ALWAYS fetches
    ...
}
```

**Fix**: Add a `DateTime? _lastFetch` field and skip fetch if within 30 minutes. Use `generatedAt` from backend response as the cache key.

---

## 5. YouTube API Calls — No Quota Management

**Files**:
- `lib/services/youtube_engine/youtube_explode_engine.dart` (lines 207–232)
- `lib/services/youtube_engine/newpipe_engine.dart` (lines 137–149)
- `lib/services/connectivity/engine_failover.dart` (lines 29–93)

| File:Line | Issue | Severity | Fix |
|-----------|-------|----------|-----|
| `youtube_explode_engine.dart:207–209` | `getVideo()` — no throttle | **HIGH** | Max 10 calls/minute per video ID |
| `youtube_explode_engine.dart:223–232` | `searchVideos()` — no throttle | **HIGH** | Debounce search input by 500ms; max 30 searches/minute |
| `youtube_explode_engine.dart:160–204` | `getStreamManifest()` — no throttle | **HIGH** | Cache manifests for 6 hours (YouTube stream URLs are stable) |
| `newpipe_engine.dart:137–149` | `searchVideos()` — no throttle | **MEDIUM** | Same debounce as youtube_explode |
| `engine_failover.dart:41–93` | Retry logic (5× per engine × 3 engines = 15 attempts) | **LOW** | Good — but each attempt hits YouTube. Add a global per-minute call counter. |

**Risk**: The engine failover retries up to 5 times per engine with exponential backoff (1s→16s). With 3 engines (youtube_explode → yt-dlp → NewPipe), a single failed play could generate 15 YouTube API calls. No global throttle exists — a rapid skip through 20 tracks could generate 300+ calls.

**Fix**: Add a global `_youtubeCallCounter` with a sliding window (max 60 calls/minute across all engines). Track per-video manifest cache with TTL.

---

## 6. Connection Checker — DNS Flooding Risk

**File**: `lib/services/connectivity/connection_checker.dart` (lines 7–36)

**Issue**: The `ConnectionChecker` pings `8.8.8.8` + `1.1.1.1` 4× each via `InternetAddress.lookup()`. The `isConnected` getter has a 30-second result cache, which is good. However, `connectivity_adapter.dart` also does similar checks and may bypass the cache.

**Severity**: **LOW** — mitigated by 30s cache, but worth noting.

---

## 7. Connect Feature WebSocket — No Message Rate Limiting

**File**: `lib/provider/connect/connect.dart` (lines 56–226) + `lib/provider/server/routes/connect.dart` (lines 41–246)

| File:Line | Issue | Severity | Fix |
|-----------|-------|----------|-----|
| `connect.dart:164–169` | `emit()` — sends messages to WebSocket with no rate limit | **MEDIUM** | Throttle to 10 messages/second; queue overflow events |
| `server/routes/connect.dart:154–243` | Server processes all WebSocket messages with no rate limiting | **HIGH** | Add per-client message rate limit (50 msg/sec); drop/close on abuse |

**Risk**: The Connect feature allows remote control of the audio player. A malicious or buggy client could flood the WebSocket with `position` or `volume` update events at thousands per second, causing UI freezes.

---

## Summary

| Area | Finding Count | Critical Issues |
|------|---------------|-----------------|
| Auth rate limiting | 7 methods unguarded | `_authToken()`, `registerEmail()`, `loginEmail()` |
| Catalog writes | 3 methods unguarded | Moderate risk (user-facing, not admin) |
| Wallet/payments | 4 methods unguarded | `pushSong()`, `createCheckout()` — financial risk |
| Leaderboard/recommendations | 4 caching gaps | `fetchRecommendations()` called on every UI render |
| YouTube API | 4 unthrottled endpoints | `searchVideos()` unbounded, manifests uncached |
| Connect WebSocket | 2 rate-limit gaps | Server-side message flood risk |

**Overall**: The DeeMusiq Flutter client has **zero client-side rate limiting** across all API categories. The backend (per CHANGELOG) implements server-side rate limiting on `/auth/*` and `/integrity/report`, but the client should not rely solely on server-side protection — especially for wallet operations where double-submission could cause financial errors even with server-side idempotency.
