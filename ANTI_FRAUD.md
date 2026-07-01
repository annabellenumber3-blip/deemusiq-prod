# DeeMusiq Anti-Fraud System — Audit & Recommendations

## Status: MULTIPLE CRITICAL & HIGH-SEVERITY GAPS IDENTIFIED

This document covers:
1. Track creation / artist impersonation prevention
2. Content reporting mechanism
3. Verified artist badges
4. Proof of authorship
5. General anti-fraud hardening

---

## 1. Backend: Track creation tied to authenticated artist account

### Finding: GAP — CRITICAL
**File:** `backend/src/routes/catalog.ts:131-143`

The catalog (track/artist/album creation) is protected by `requireAdmin` (a single `x-admin-key` header check), NOT by per-artist authentication. Any admin-key holder can create tracks under any artist name. There is no concept of an "artist user account" separate from the admin operator.

**Current state:**
- `catalogRouter.use(requireAdmin)` at line 15 makes ALL catalog CRUD admin-only
- No per-artist authentication or ownership model exists
- Artists cannot self-publish tracks — only the operator can

**Fix required:**
1. Extend the `User` model with a `role` field (`user` | `artist` | `admin`)
2. Add an `ownerUserId` field to the `Artist` model
3. Create non-admin catalog endpoints requiring artist-authenticated sessions
4. Validate that only the owning artist (or admin) can publish/release under their name
5. Track creation must validate `artistId` matches the authenticated user's owned artist

---

## 2. Backend: Artist name verification

### Finding: GAP — HIGH
**File:** `backend/prisma/schema.prisma:124-139` (Artist model)
**File:** `backend/src/routes/catalog.ts:21-35` (artist creation)

The `Artist` model has a `verified: Boolean` field (line 129), but:
- No verification workflow exists — the field is simply a boolean set by admin
- No mechanism prevents registering an artist with a name matching an existing verified artist
- No uniqueness constraint on artist names (only an index at line 137, not `@unique`)

**Fix required:**
1. Add `@unique` constraint on `Artist.name`
2. Implement an artist claim/verification flow:
   - Artist submits a "claim" request with proof (see §6)
   - Admin reviews and sets `verified = true`
   - Once verified, no other user can create a track under that artist name
3. For unverified artists, track creation should flag the artist as "unverified" in the API response

---

## 3. Backend: ContentReport model

### Finding: MISSING — HIGH
**File:** `backend/prisma/schema.prisma` — no ContentReport model exists

There is no mechanism for users to flag impersonation, fake content, or policy violations.

**Fix — add to schema.prisma:**
```prisma
model ContentReport {
  id          String   @id @default(uuid())
  reporterId  String
  reporter    User     @relation(fields: [reporterId], references: [id], onDelete: Cascade)
  trackId     String?
  track       Track?   @relation(fields: [trackId], references: [id], onDelete: SetNull)
  artistId    String?
  artist      Artist?  @relation(fields: [artistId], references: [id], onDelete: SetNull)
  reason      String   // impersonation | fake_content | copyright | spam | other
  details     String?
  status      String   @default("pending") // pending | reviewed | resolved | dismissed
  createdAt   DateTime @default(now())
  reviewedAt  DateTime?

  @@index([status])
  @@index([trackId])
  @@index([artistId])
}
```

Also need a `POST /reports` route (authenticated) accepting `{ trackId?, artistId?, reason, details }`.

---

## 4. App: "Verified Artist" badge

### Finding: MISSING — HIGH
**File:** Flutter app — no verified badge UI found

The backend `Artist` model already has `verified: Boolean` and the `artistDto()` function in `backend/src/metadata.ts:83-97` includes it in the response. However, the Flutter app does not render any verified badge on artist profiles.

**Fix required:**
1. Parse the `verified` field from artist API responses
2. Display a checkmark badge (e.g., ✅ or a styled "Verified Artist" chip) on:
   - Artist profile header
   - Track listings (next to artist name)
   - Search results

---

## 5. App: Report button on tracks

### Finding: MISSING — HIGH
**File:** Flutter app — no report button found on track tiles or track detail

Every track should have a "Report" option in its context menu (alongside "Add to playlist", "Share", etc.) that opens a dialog where users can select a reason and submit a report to the backend.

**Fix required:**
1. Add a "Report" action to track context menus
2. Create a report dialog with reason selection (impersonation, fake content, etc.)
3. Call `POST /reports` with track metadata
4. Show a confirmation toast after submission

---

## 6. Proof of authorship

### Finding: NOT IMPLEMENTED — HIGH

There is no mechanism for artists to prove they own or created a track. The task spec requests:
> Design "proof of authorship" — artist uploads short video or links existing social media

**Recommended design:**

### 6a. Social media verification (low-friction)
Artist links an existing social media profile (Twitter/X, Instagram, TikTok, YouTube) during the verification flow. The backend:
1. Generates a unique verification code
2. Artist posts the code publicly on their verified social media account
3. Backend scrapes/checks the social media profile for the code
4. On match, marks the artist as `verified: true`

### 6b. Proof video upload (high-assurance)
Artist uploads a short (15-30s) video of themselves performing/speaking about the track. The video:
1. Is stored in object storage (S3/R2)
2. Is reviewed by admin or community moderators
3. Is NOT made public (privacy-preserving)

### 6c. Implementation additions
- `Artist.proofType`: `social` | `video` | `none`
- `Artist.proofUrl`: link to social post or stored video key
- `Artist.verificationRequestedAt`: DateTime
- Add `POST /artists/:id/claim` endpoint (artist-authenticated)
- Add `POST /artists/:id/verify` endpoint (admin-only, sets verified + proof metadata)

---

## 7. Additional anti-fraud hardening

### 7a. Song push validation — HIGH
**File:** `backend/src/wallet.ts:100-148`

`pushSong()` writes a `SongPush` record with whatever `songId`, `title`, and `artist` the client sends — no validation that:
- `songId` corresponds to a real track
- `artist` matches the track's actual artist
- The song hasn't been deleted/removed

**Fix:** Validate `songId` against the catalog before creating the push record. If the song doesn't exist, reject the push (prevents token spending on fake/deleted tracks).

### 7b. Require auth for wallet routes — MEDIUM
**File:** `backend/src/routes/wallet.ts` (entire file)

Wallet route handlers cast `req as AuthedRequest` and use `userId!` without checking it was set. The `requireAuth` middleware is applied in `index.ts:176`, but the route file doesn't import or call it. If someone mounts the wallet router elsewhere without auth middleware, all wallet operations would be unauthenticated.

**Fix:** Add `walletRouter.use(requireAuth)` at the top of `backend/src/routes/wallet.ts` as a defense-in-depth measure.

### 7c. Rate limiting on push/support — MEDIUM
**File:** `backend/src/index.ts:73-79`

The global rate limiter applies uniformly to all routes except webhooks. Consider adding tighter per-user rate limits on wallet mutation endpoints (`/wallet/push`, `/wallet/support`) to prevent token abuse/spam.

### 7d. Token balance derivation — VERIFIED CORRECT ✓
**File:** `backend/src/wallet.ts:27-33`

The balance is correctly computed as `SUM(tokens)` from `WalletTransaction`. No stored balance field exists — this is the correct audit pattern.

---

## Summary of actionable items

| # | Severity | Area | Gap |
|---|----------|------|-----|
| 1 | CRITICAL | API Contract | `GET /catalog` called by Flutter app has no backend endpoint (admin-only `/catalog` can't serve public catalog) |
| 2 | CRITICAL | Anti-fraud | No per-artist authentication; tracks created by admin only, no artist ownership |
| 3 | HIGH | Anti-fraud | Artist name not unique — anyone can create duplicate artist names |
| 4 | HIGH | Anti-fraud | No ContentReport model or reporting API |
| 5 | HIGH | App UI | No "Verified Artist" badge rendered in the Flutter app |
| 6 | HIGH | App UI | No report button on tracks |
| 7 | HIGH | Anti-fraud | No proof-of-authorship mechanism |
| 8 | HIGH | Deep link | URL construction mismatch between backend and Dart app (host vs path) |
| 9 | MEDIUM | Validation | `pushSong` doesn't verify songId exists in catalog |
| 10 | MEDIUM | Defense | Wallet route file doesn't self-apply `requireAuth` (relies on index.ts mount) |
| 11 | MEDIUM | Validation | `POST /recommendations/like` and `/unlike` don't use zod validation |
