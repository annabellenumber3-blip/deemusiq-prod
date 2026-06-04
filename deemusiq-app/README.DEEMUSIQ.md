# DeeMusiq — App (rebranded Spotube)

> *It's a drop day.* This folder is the **DeeMusiq Android/desktop app**, a rebrand of the
> open-source [Spotube](https://github.com/KRTirtho/spotube) engine (BSD-4-Clause — see
> [`NOTICE.md`](./NOTICE.md)).

**Heads-up (honest status):** the source has been fully rebranded to DeeMusiq, but the
actual installable file (`.apk`) is **built in the cloud by GitHub Actions** — not on this
machine (Flutter isn't installed here, and Spotube is a large Flutter app). You don't need
to install anything: push this folder to GitHub and click one button. ⬇️

---

## 🟢 Build the DeeMusiq APK (no coding, ~15–25 min in the cloud)

1. Create a **free** GitHub account at <https://github.com> if you don't have one.
2. Make a new repository, e.g. `deemusiq-app` (Public or Private both work).
3. Upload **everything in this `deemusiq-app` folder** to it (drag-and-drop on the repo
   page → *uploading an existing file*), and **Commit**.
4. Open the **Actions** tab → enable workflows if prompted →
   pick **“Build DeeMusiq (Android APK)”** → **Run workflow**.
5. Wait for the green tick. Open the finished run → **Artifacts** → download
   **`DeeMusiq-apk`**. Inside is **`DeeMusiq.apk`**.
6. Send that APK to an Android phone, tap it, allow “install from unknown sources”. Done. 🎉

### Make it a public download (auto-attached to a Release)
Instead of step 4, create a **tag** named `v1.0.0` (repo → Releases → Draft a new release →
choose a tag `v1.0.0` → Publish). The workflow runs automatically and attaches
`DeeMusiq.apk` to that Release. The public download link is then:

```
https://github.com/<your-username>/deemusiq-app/releases/latest/download/DeeMusiq.apk
```

Paste that link into the **website** (`deemusiq-site/js/main.js` → `DOWNLOADS.android`).

---

## 🔐 Signing (important before you go public)

The first build auto-creates a **temporary** signing key so the APK installs immediately
for testing. For a real public release, set a **permanent** keystore so that future updates
install over older versions. One-time setup:

1. On any computer with Java, create a keystore:
   ```bash
   keytool -genkeypair -v -keystore deemusiq.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias deemusiq \
     -dname "CN=DeeMusiq, O=The Dembe Group, C=ZA"
   ```
   (it asks you to set a password — remember it)
2. Turn it into text: `base64 -w0 deemusiq.jks > keystore.txt`
3. In your GitHub repo → **Settings → Secrets and variables → Actions → New secret**, add:
   | Secret name | Value |
   |-------------|-------|
   | `KEYSTORE_BASE64` | the contents of `keystore.txt` |
   | `KEYSTORE_PASSWORD` | the password you chose |
   | `KEY_ALIAS` | `deemusiq` |
   | `KEY_PASSWORD` | the password you chose |
4. Re-run the workflow — it now signs with your permanent key.

⚠️ Keep `deemusiq.jks` and its passwords safe. If you lose them you can't ship updates
to already-installed users.

---

## What was rebranded
See [`NOTICE.md`](./NOTICE.md) for the full list. In short: every place a user sees
“Spotube” now says **DeeMusiq**, the icon/splash/accent use your orange hexagon, and the
Android app id is `za.co.deemusiq.app`. Internal code names were intentionally left alone
so the app keeps building.

## Building other platforms (Windows / Linux / macOS / iOS)
The display names for those are already rebranded too. Building them needs more setup
(packaging, Apple/Windows signing). The upstream Spotube build commands still apply —
start from `dart cli/cli.dart build <platform>`. Ask and I can add a desktop workflow.

## Honest caveats
- I could **not compile/test** the build in this environment, so the **first** Actions run
  may surface a small fix (a dependency or a Flutter-version nudge). That's normal for a
  big Flutter app — tell me the error and I'll patch the workflow.
- This app streams metadata/audio the same way Spotube does (Spotify metadata + YouTube
  audio). It does **not** host your own artists' uploads — that's the separate “real
  DeeMusiq platform” we discussed. This rebrand is exactly what you asked for: *Spotube,
  renamed to DeeMusiq.*
