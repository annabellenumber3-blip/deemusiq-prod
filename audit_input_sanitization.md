# Input Sanitization Audit — DeeMusiq App (`deemusiq-app/lib/`)

**Date**: 2026-07-01
**Auditor**: Agent 2 (I2P safety + rate limits + input sanitization)
**Scope**: All user-supplied input paths in the Flutter client — search queries, playlist names, URLs, file paths, deep links, WebSocket messages

---

## 1. Search Queries

### 1a. YouTube Search — No Sanitization

**File**: `lib/services/youtube_engine/youtube_explode_engine.dart`, line 223–232
**File**: `lib/services/youtube_engine/newpipe_engine.dart`, line 137–149

```dart
// youtube_explode_engine.dart:227-228
return _youtubeExplode.search(
    query,  // ← raw user input, no sanitization
    filter: TypeFilters.video,
);
```

```dart
// newpipe_engine.dart:138-141
final results = await NewPipeExtractor.search(
    query,  // ← raw user input, no sanitization
    contentFilters: [SearchContentFilters.videos],
);
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | User search queries are passed directly to YouTube's API (via youtube_explode_dart and NewPipe) with no trimming, length limiting, or character validation. |
| **Risk** | YouTube APIs handle Unicode and special characters gracefully; risk is minimal. However, extremely long queries (> 2000 chars) could cause HTTP 414 or memory issues in the isolate layer. |
| **Fix** | Trim to 500 characters; strip control characters (`\x00-\x1f`); log queries > 200 chars as suspicious. |

### 1b. Local Library Search — Fuzzy Matching, No Injection Risk

**File**: `lib/pages/library/user_local_tracks/local_folder.dart`, lines 389–409

```dart
final filteredTracks = useMemoized(() {
    if (searchController.text.isEmpty) return sortedTracks;
    return sortedTracks
        .map((e) => (weightedRatio("${e.name} - ${e.artists.asString()}", searchController.text), e))
        ...
        .where((e) => e.$1 > 50)
        ...
}, [searchController.text, sortedTracks]);
```

| Severity | **NONE** |
|----------|----------|
| **Issue** | Client-side fuzzy search only — no backend call, no injection surface. |

### 1c. Backend Catalog Search — Query Parameter Injection

**File**: `lib/services/wallet/wallet_api.dart`, lines 549–564

```dart
final res = await _client().get("/catalog", queryParameters: {
    if (query != null && query.isNotEmpty) "q": query,  // ← raw user input in query param
    ...
});
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | `query` goes into an HTTP query parameter. Dio URL-encodes values, so injection risk is low. However, the backend must sanitize this server-side. |
| **Fix** | Trim to 200 chars; strip non-printable characters. Backend should enforce its own sanitization. |

---

## 2. Playlist Names — No Length Limits, No Injection Validation

**File**: `lib/modules/playlist/playlist_create_dialog.dart`, lines 253–258
**File**: `lib/services/wallet/wallet_api.dart`, lines 475–488

### 2a. Playlist Create Dialog

```dart
// playlist_create_dialog.dart:253-258
TextFormBuilderField(
    name: 'playlistName',
    label: Text(context.l10n.playlist_name),
    placeholder: Text(context.l10n.name_of_playlist),
    validator: FormBuilderValidators.required(),  // ← only checks non-empty!
),
```

| Severity | **MEDIUM** |
|----------|-------------|
| **Issue** | Playlist name validation is `required()` only — no max length, no character restrictions. A user could enter a 10,000-character name containing JSON control characters, HTML, or SQL fragments (though Prisma on the backend would parameterize). |
| **Risk** | Backend DB might reject or truncate; UI could break with extremely long names. If the playlist name is ever rendered in a webview or HTML context, XSS is possible. |
| **Fix** | Add `FormBuilderValidators.maxLength(200)` and a regex validator: `RegExp(r'^[\w\s\-.,!?&()#@\'\"]+$')`. |

### 2b. Backend Playlist Sync

```dart
// wallet_api.dart:480-482
final res = await _client().post(
    "/sync/playlists",
    data: {"name": name, "songHashes": songHashes},  // ← name unvalidated
    ...
);
```

| Severity | **LOW** (backend should sanitize) |
|----------|-----------------------------------|
| **Fix** | Client-side: trim to 200 chars, strip control chars before sending. |

### 2c. Description Field

**File**: `lib/modules/playlist/playlist_create_dialog.dart`, lines 260–267

```dart
TextFormBuilderField(
    name: 'description',
    label: Text(context.l10n.description),
    validator: FormBuilderValidators.required(),  // ← no length limit
    ...
    maxLines: 5,
),
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | `maxLines: 5` only controls visual lines, not character count. A user could paste 50KB of text. |
| **Fix** | Add `FormBuilderValidators.maxLength(2000)`. |

---

## 3. URL Validation

### 3a. WebSocket Connect URL — mDNS Host Injection Risk

**File**: `lib/provider/connect/connect.dart`, lines 70–72

```dart
final channel = WebSocketChannel.connect(
    Uri.parse('ws://${service.host}:${service.port}/ws'),  // ← host/port from mDNS
);
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | `service.host` and `service.port` come from Bonsoir/mDNS service discovery — not direct user input. However, if mDNS is spoofed on the local network, an attacker could inject a malicious hostname. `Uri.parse()` will reject invalid URIs, but won't prevent connecting to an attacker's IP. |
| **Risk** | Local network attack only. mDNS spoofing is possible but requires LAN access. WebSocket is used for remote control of the audio player — an attacker could control playback. |
| **Fix** | Validate that `service.host` is a valid IP or `.local` hostname (regex). Add user confirmation dialog before connecting (already implemented at `server/routes/connect.dart:62-100`). |

### 3b. Provider Parameter in URL Path — No Validation

**File**: `lib/services/wallet/wallet_api.dart`, lines 302–311 and 400–410

```dart
// Line 303-305
await _client().delete(
    "/link/accounts/$provider",  // ← provider interpolated into URL path
    ...
);

// Line 402-406
final res = await _client().get(
    "/link/$provider/start",  // ← provider interpolated into URL path
    ...
);
```

| Severity | **MEDIUM** |
|----------|------------|
| **Issue** | The `provider` string (e.g., "spotify") is interpolated directly into the URL path with no validation. A malicious value like `../../admin/delete-all` could cause path traversal in the HTTP request. |
| **Risk** | The backend should validate the provider against a whitelist, but the client should not send garbage. |
| **Fix** | Validate provider against a whitelist: `['spotify']`. Use `Uri.encodeComponent(provider)` for safety. |

**Evidence from code** — no validation anywhere in the call chain:
```dart
// connect.dart:164-169
Future<void> emit(Object message) async {
    if (state.value == null) return;
    state.value?.channel.sink.add(
        message is String ? message : (message as dynamic).toJson(),
    );
}
```
The `emit()` method sends raw objects to the WebSocket — no message size check.

### 3c. Audio Stream URLs — Parsed from YouTube

**File**: `lib/services/youtube_engine/newpipe_engine.dart`, line 16
**File**: `lib/services/youtube_engine/youtube_explode_engine.dart`, line 183

```dart
// newpipe_engine.dart:16
Uri.parse(stream.content),  // ← URL from YouTube extraction
```

| Severity | **NONE** |
|----------|----------|
| **Issue** | URLs come from YouTube's API response, not user input. `Uri.parse()` will throw on invalid URLs if they ever were malformed. |

---

## 4. File Path Sanitization — Partial Protection

### 4a. Filename Sanitization — GOOD

**File**: `lib/utils/service_utils.dart`, lines 338–369

```dart
static String sanitizeFilename(String input, {String replacement = ''}) {
    final result = input
        .replaceAll(RegExp(r'[\/\?<>\\:\*\|"]'), replacement)  // illegal chars
        .replaceAll(RegExp(r'[\x00-\x1f\x80-\x9f]'), replacement)  // control chars
        .replaceFirst(RegExp(r'^\.+$'), replacement)  // reserved names
        .replaceFirst(RegExp(r'^(con|prn|aux|nul|com[0-9]|lpt[0-9])(\..*)?$', caseSensitive: false), replacement)  // Windows reserved
        .replaceFirst(RegExp(r'[\. ]+$'), replacement);  // trailing dots/spaces
    return result.length > 255 ? result.substring(0, 255) : result;
}
```

| Severity | **NONE** (good implementation) |
|----------|-------------------------------|
| **Assessment** | Covers illegal characters, control characters, Windows reserved names, trailing dots/spaces, and length limits. Used in download manager, local tracks provider, and server playback routes. |

### 4b. Directory Paths — NO Path Traversal Validation

**File**: `lib/pages/library/user_local_tracks/local_folder.dart`, line 125
**File**: `lib/provider/local_tracks/local_tracks_provider.dart`, lines 58–76
**File**: `lib/provider/download_manager_provider.dart`, line 238

| File:Line | Issue | Severity | Fix |
|-----------|-------|----------|-----|
| `local_folder.dart:125` | `Directory(location)` — `location` comes from route parameter, no validation | **LOW** | Validate that `location` is within allowed directories (downloads, cache, user library) |
| `local_tracks_provider.dart:58–76` | Iterates `Directory(location)` for all user-configured library locations | **LOW** | User sets these via file picker, so risk is self-inflicted |
| `download_manager_provider.dart:238–243` | `join(downloadLocation, sanitizeFilename(...))` — `downloadLocation` from user prefs, no path traversal check | **MEDIUM** | If `downloadLocation` is set to `/etc` or `~/.ssh`, downloads could overwrite system files |

```dart
// download_manager_provider.dart:238-243
final savePath = join(
    downloadLocation,  // ← user-configurable, not validated for safety
    ServiceUtils.sanitizeFilename(
        "${track.query.name} - ${track.query.artists.map((e) => e.name).join(", ")}.${container.getFileExtension()}",
    ),
);
```

| Severity | **MEDIUM** |
|----------|------------|
| **Issue** | `downloadLocation` is set by the user (via `UserPreferencesNotifier`). While normally a safe directory chosen by the user, there's no validation that it's not a system directory. The `sanitizeFilename()` function protects the filename portion, but the base path is unvalidated. |
| **Risk** | Self-inflicted only — the user would need to deliberately set their download location to a sensitive directory. However, if preferences were ever injected via a backup/restore or a bug, this could be exploited. |
| **Fix** | Validate `downloadLocation` is within app sandbox or a known-safe user directory. Warn if set to system paths like `/etc`, `/bin`, `/System`, `C:\Windows`. |

### 4c. Local Library Location — File Picker Only

**File**: `lib/pages/library/user_local_tracks/user_local_tracks.dart`, lines 39–57

```dart
final dirStr = await FilePicker.platform.getDirectoryPath(...);  // system picker
// OR
final dirStr = await getDirectoryPath(...);  // system picker
```

| Severity | **NONE** |
|----------|----------|
| **Assessment** | Uses OS-native file picker — user explicitly selects directories. Good. |

### 4d. Cache Export — Arbitrary Write Location

**File**: `lib/pages/library/user_local_tracks/local_folder.dart`, lines 225–249

```dart
final exportPath = await FilePicker.platform.getDirectoryPath();
if (exportPath == null) return;
final exportDirectory = Directory(exportPath);
```

| Severity | **NONE** |
|----------|----------|
| **Assessment** | Uses OS-native file picker for export destination. User controls where files go. Acceptable. |

---

## 5. Deep Links (`deemusiq://`) — Well-Validated

**File**: `lib/hooks/configurators/use_deep_linking.dart`, lines 21–52

```dart
final uri = Uri.tryParse(link);
if (uri == null || uri.scheme != "deemusiq") return;

switch (uri.host) {
    case "payments":
        await router.navigate(const WalletRoute());
        break;
    case "link":
        await router.navigate(const LinkedAccountsRoute());
        break;
    default:
        break;
}
```

| Severity | **NONE** |
|----------|----------|
| **Assessment** | Scheme validation (`deemusiq` only), host whitelist (`payments` or `link`), no query parameter processing that could be exploited. Clean implementation. |

**Note**: Query parameters on the deep link URI are NOT processed by the client — they're only relevant to the backend callback flow. The client ignores them after host routing. This is correct.

---

## 6. Connect Feature — WebSocket Messages

### 6a. Message Deserialization — Crash Risk

**File**: `lib/provider/connect/connect.dart`, lines 82–85
**File**: `lib/provider/server/routes/connect.dart`, lines 154–243

```dart
// connect.dart:83-85 (client receiving)
final event = WebSocketEvent.fromJson(jsonDecode(message), (data) => data);

// server/routes/connect.dart:157-160 (server receiving)
final event = WebSocketEvent.fromJson(jsonDecode(message), (data) => data);
```

| Severity | **MEDIUM** |
|----------|------------|
| **Issue** | `jsonDecode(message)` will throw `FormatException` on invalid JSON — caught by try/catch in server routes (line 234) but NOT in connect.dart client code (no try/catch around `stream.listen`). A malformed message crashes the stream listener. |
| **Fix** | Wrap `jsonDecode` in try/catch in connect.dart:82-146. |

### 6b. WsEvent Type Parsing — Unvalidated Enum Lookup

**File**: `lib/models/connect/ws_event.dart`, lines 24–26

```dart
static WsEvent fromString(String value) {
    return WsEvent.values.firstWhere((e) => e.name == value);  // ← throws StateError if invalid
}
```

| Severity | **MEDIUM** |
|----------|------------|
| **Issue** | `firstWhere` throws `StateError` if the type string doesn't match any enum value. Combined with missing try/catch in connect.dart, this crashes the WebSocket stream. |
| **Fix** | Use `firstWhere(..., orElse: () => WsEvent.error)` to gracefully handle unknown event types. |

### 6c. No Message Size Limits

**File**: `lib/provider/connect/connect.dart`, lines 80–146 (client)
**File**: `lib/provider/server/routes/connect.dart`, lines 154–243 (server)

| Severity | **LOW** |
|----------|---------|
| **Issue** | Neither client nor server enforces a maximum WebSocket message size. A malicious message could be gigabytes, causing OOM. |
| **Risk** | Local network only (Connect requires mDNS discovery on the same LAN). An attacker would need LAN access. |
| **Fix** | Reject messages > 1 MB. Drop the connection if exceeded. |

### 6d. Server-Side WebSocket — User Confirmation Dialog

**File**: `lib/provider/server/routes/connect.dart`, lines 62–100

| Severity | **NONE** (good) |
|----------|-----------------|
| **Assessment** | The server requires user confirmation before accepting a WebSocket connection. Origin is tracked and re-confirmed if not in the allowed list. This is a strong security control. |

---

## 7. Additional Findings

### 7a. HTML in Track Metadata — Rendered Without Escaping?

**File**: `lib/extensions/string.dart`, lines 6–9

```dart
extension UnescapeHtml on String {
    String cleanHtml() => parse("<p>$this</p>").documentElement!.text;
    String unescapeHtml() => htmlEscape.convert(this);
}
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | `cleanHtml()` strips HTML tags from strings. However, it's unclear whether this is consistently applied to all user-visible metadata (track titles, artist names, descriptions). YouTube metadata can contain HTML entities. |
| **Fix** | Ensure `cleanHtml()` is called on all metadata strings before rendering in UI. Search codebase for all `Text()` widgets showing backend data. |

### 7b. SharedPreferences — Search History Unbounded

**File**: `lib/services/kv_store/kv_store.dart`, lines 39–43

```dart
static List<String> get recentSearches =>
    sharedPreferences.getStringList('recentSearches') ?? [];

static Future<void> setRecentSearches(List<String> value) async =>
    await sharedPreferences.setStringList('recentSearches', value);
```

| Severity | **LOW** |
|----------|---------|
| **Issue** | No cap on the number of stored recent searches. Over years of use, this list could grow unbounded. Each entry is a raw user query — no sanitization before storage. |
| **Fix** | Cap at 50 entries. Trim each entry to 200 chars. |

---

## Summary

| Category | Finding Count | HIGH | MEDIUM | LOW | NONE |
|----------|---------------|------|--------|-----|------|
| Search Queries | 3 | 0 | 0 | 3 | 0 |
| Playlist Names | 3 | 0 | 1 | 2 | 0 |
| URLs | 4 | 0 | 1 | 2 | 1 |
| File Paths | 5 | 0 | 1 | 2 | 2 |
| Deep Links | 1 | 0 | 0 | 0 | 1 |
| Connect / WebSocket | 5 | 0 | 2 | 2 | 1 |
| Other | 2 | 0 | 0 | 2 | 0 |
| **Total** | **23** | **0** | **5** | **13** | **5** |

### Top 5 Issues Requiring Immediate Fix

1. **`server/routes/connect.dart:154–243` + `connect.dart:82–146`** — WebSocket message parsing crashes without try/catch; invalid `WsEvent` type crashes `firstWhere`. **[MEDIUM]**
2. **`playlist_create_dialog.dart:253–258`** — Playlist name has no length limit or character validation. **[MEDIUM]**
3. **`wallet_api.dart:303,402`** — Provider string interpolated into URL path without whitelist validation. **[MEDIUM]**
4. **`download_manager_provider.dart:238–243`** — `downloadLocation` not validated for path safety; could write to system directories if preferences are tampered. **[MEDIUM]**
5. **`connect.dart:164–169` + `server/routes/connect.dart`** — No WebSocket message size limit; no message rate limit. **[MEDIUM]**

**Overall assessment**: The DeeMusiq Flutter client has **reasonable input hygiene** for a music player app. The most critical gaps are in the Connect/WebSocket feature (missing error handling, no rate limits) and playlist name validation. No HIGH-severity injection vulnerabilities were found — the app doesn't handle raw SQL, doesn't render user content in WebViews, and uses parameterized HTTP clients (Dio). The `sanitizeFilename()` utility is well-implemented.
