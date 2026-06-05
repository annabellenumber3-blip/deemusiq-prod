# Changelog

All notable changes to the DeeMusiq project (website + rebranded app) are recorded here.
Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### 2026-06-05 — Code audit pass #2 (rebrand integrity + crash-path verification)

Went deeper into the files the rebrand touched. **No new fixes required** — all edits
are structurally valid and the one risky Dart change is confirmed safe (not assumed).

#### Verified
- **All 30 localization `.arb` files still parse as valid JSON** after the blanket
  `Spotube`→`DeeMusiq` value replacement (l10n keys are lowercase `spotube`, untouched).
- **`pubspec.yaml` and `flutter_launcher_icons.yaml` parse as valid YAML**; the four
  edited iOS `*.plist` files are well-formed XML.
- **Accent-colour default is NOT a crash path** (this was a genuine concern).
  `SpotubeColor(0xFFFF5722, …)` is type-valid (`SpotubeColor extends Color`, int arg).
  The picker's `firstWhere` (`color_scheme_picker_dialog.dart:109`) iterates the
  palette's *own* elements, so it always matches; the active-swatch lookup uses
  `firstWhereOrNull` (null-safe). Worst case: no preset pre-highlighted — cosmetic.
- **Website structure**: no duplicate `id`s, no dangling `#anchor` links, balanced
  `section`/`form`/`main`/`header`/`footer` tags.

### 2026-06-05 — Code audit pass #1 (bugs / unsafe handling / CI robustness)

Scope: the DeeMusiq-authored code — the website (`deemusiq-site/`), the CI
workflows, and the rebrand edits. The upstream **Spotube** engine inside
`deemusiq-app/lib/` is third-party (BSD-4-Clause) and was **not** audited here.

#### Fixed
- **Contact form always sent a blank name (real bug).**
  `deemusiq-site/js/main.js` read the name field via `form.name`, which resolves
  to the form element's own `name` attribute (empty), not `<input name="name">`.
  Result: every submitted email had an empty *Name* and a dangling subject line.
  Now reads all fields via `form.elements.namedItem(...)`. The other fields
  (`email`/`topic`/`message`) worked only by accident (no same-named property on
  `HTMLFormElement`) and were made explicit too.
- **CI could grab the wrong APK / fail silently.**
  Both `deemusiq-android.yml` workflows selected the APK with
  `find … -name "*-stable-release.apk" -o -name "*.apk" | head -1`, whose result
  depends on filesystem ordering and could pick an unintended APK. Replaced with
  a deterministic preference (`app-stable-release.apk` → `*-release.apk` → `*.apk`)
  using `-print -quit`, plus an explicit `::error::` + `exit 1` if no APK is found,
  so a broken build fails loudly instead of uploading nothing.

#### Verified (no change needed)
- Contact form builds its `mailto:` with `encodeURIComponent()` on subject/body —
  no injection vector; the site reflects no user input into the DOM.
- GitHub Actions secrets are passed via `env:` (not interpolated into `run:`), and
  `github.ref_name` appears only in release `name`/`body` — no command-injection path.
- Download buttons degrade gracefully: empty `DOWNLOADS` entries route to the
  contact form; `href="#contact"` is a no-JS fallback.
- Static site — no server, no OOM/back-pressure surface; count-up animation is
  bounded by `requestAnimationFrame` over a fixed 1s.

#### Known / cosmetic (tracked, not blocking)
- The in-app accent default was set to DeeMusiq orange (`0xFFFF5722`) with a custom
  name; the settings colour-picker may not highlight it as a preset selection. UI-only.
- The app's data directory was renamed `Spotube` → `DeeMusiq`; on a device that had
  the original Spotube installed this would not migrate old data. Irrelevant for a
  fresh install.

#### Not audited
- Upstream Spotube engine (`deemusiq-app/lib/**`, 270+ files) — third-party code.
  Only user-facing branding strings in it were changed during the rebrand.

---

### 2026-06-04/05 — Initial delivery
- Added `deemusiq-site/` — static, responsive GitHub-Pages website (dark honeycomb
  theme, brand orange `#FF5722`, contact details from the client concept doc).
- Added `deemusiq-app/` — Spotube rebranded to **DeeMusiq** across all platforms
  (display name, app id `za.co.deemusiq.app`, icon/splash, accent colour), with a
  GitHub Actions workflow that builds the Android APK. Attribution kept in `NOTICE.md`.
- Published everything to a private GitHub repo.
