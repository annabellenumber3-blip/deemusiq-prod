# NOTICE — DeeMusiq app attribution

The **DeeMusiq** application is a rebrand/derivative of **Spotube**, an open-source
project by **Kingkor Roy Tirtho** and contributors.

> This product includes software developed by Kingkor Roy Tirtho.

- Upstream project: https://github.com/KRTirtho/spotube
- License: **BSD-4-Clause** — see [`LICENSE`](./LICENSE) (retained unchanged).

Per the BSD-4-Clause license, the original copyright notice and the acknowledgement
above are retained. The Spotube name and the names of its contributors are **not**
used to endorse or promote DeeMusiq. "DeeMusiq" branding, logo and product identity
© The Dembe Group.

## What was changed in this rebrand
Only user-facing identity was changed; the engine is unmodified Spotube:
- App display name → **DeeMusiq** (Android/iOS/macOS/Linux/Windows)
- Android application id → `za.co.deemusiq.app`
- App icon & splash → DeeMusiq hexagon logo (orange `#FF5722`)
- Default accent colour → DeeMusiq orange
- App window/title strings → DeeMusiq
- Build/release CI replaced with `deemusiq-android.yml`

The internal Dart package name remains `spotube` (changing it would rewrite
hundreds of internal imports with no user-visible benefit).
