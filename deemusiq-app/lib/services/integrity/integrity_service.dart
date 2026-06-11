import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:deemusiq/services/wallet/payment_service.dart'
    show PaymentGatewayConfig;
import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:deemusiq/utils/platform.dart';

/// Result of the most recent integrity evaluation.
///
/// - [ok]: nothing wrong detected (or checks not applicable on this platform).
/// - [walletLocked]: the installed APK does not match the hash GitHub published
///   for this release. Money features are disabled; playback keeps working.
/// - [bricked]: the build is signed with a certificate other than the pinned
///   release certificate — a repackaged app. The app refuses to run.
enum IntegrityVerdict { ok, walletLocked, bricked }

/// Anti-tamper / integrity verification.
///
/// Two independent signals, by design:
///  1. **Signing certificate** (local, offline, strong): a modified APK must be
///     re-signed with a different key, which changes this hash. When the
///     expected hash is pinned via [expectedCertSha256], a mismatch bricks the
///     app at boot. This is the primary protection and needs no network.
///  2. **Published APK hash** (online, supplementary): the app compares its own
///     on-disk APK against the SHA-256 GitHub Actions published for the release.
///     A confirmed mismatch locks the wallet and is reported to the backend; an
///     unreachable hash endpoint is treated as "unknown" and never locks anyone.
///
/// Honest limits: client-side checks raise the bar against casual repackaging
/// and give the operator telemetry, but they are not unbreakable DRM. The money
/// guarantee comes from the backend owning the crypto deposit address and
/// confirming funds on-chain — a fake app can never redirect a real top-up.
class IntegrityService {
  IntegrityService._();
  static final IntegrityService instance = IntegrityService._();

  static const MethodChannel _channel = MethodChannel("deemusiq/integrity");

  /// Expected SHA-256 of the signing certificate (lowercase hex, no colons).
  /// Set via `--dart-define=DEEMUSIQ_CERT_SHA256=...` once a PERMANENT keystore
  /// is in use. Empty => the cert check is informational only, because the
  /// temporary CI keystore produces a different certificate on every build and
  /// cannot be pinned.
  static final String expectedCertSha256 = _normalizeHash(
    const String.fromEnvironment("DEEMUSIQ_CERT_SHA256", defaultValue: ""),
  );

  /// URL of the published SHA-256 of the release APK. Defaults to the public
  /// GitHub release asset; override with `--dart-define` if self-hosting.
  static const String apkHashUrl = String.fromEnvironment(
    "DEEMUSIQ_INTEGRITY_HASH_URL",
    defaultValue:
        "https://github.com/deemusiq/deemusiq/releases/latest/download/DeeMusiq.apk.sha256",
  );

  final ValueNotifier<IntegrityVerdict> verdict =
      ValueNotifier<IntegrityVerdict>(IntegrityVerdict.ok);

  /// True when money features must be disabled (wallet locked or app bricked).
  bool get walletLocked => verdict.value != IntegrityVerdict.ok;

  Timer? _timer;
  final Random _rng = Random.secure();

  static String _normalizeHash(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^0-9a-f]'), '');

  Future<String?> _certHash() async {
    if (!kIsAndroid) return null;
    try {
      final v = await _channel.invokeMethod<String>("certSha256");
      return v == null ? null : _normalizeHash(v);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _apkHash() async {
    if (!kIsAndroid) return null;
    try {
      final v = await _channel.invokeMethod<String>("apkSha256");
      return v == null ? null : _normalizeHash(v);
    } catch (_) {
      return null;
    }
  }

  /// Current device-build hashes for login attestation, or null off Android /
  /// when unreadable. The backend binds these into the signed challenge.
  Future<({String? cert, String? apk})> attestation() async {
    return (cert: await _certHash(), apk: await _apkHash());
  }

  /// LOCAL, offline boot gate. Returns false ONLY when the certificate is
  /// pinned ([expectedCertSha256] set) and the running build is signed with a
  /// different key (a repackaged APK). Returns true in every other case — not
  /// Android, not pinned, or the hash can't be read — so a legitimate offline
  /// build always starts.
  Future<bool> bootCheckPassed() async {
    if (!kIsAndroid || expectedCertSha256.isEmpty) return true;
    final cert = await _certHash();
    if (cert == null) return true; // can't read -> don't brick on a maybe
    if (cert == expectedCertSha256) return true;
    verdict.value = IntegrityVerdict.bricked;
    // Fire-and-forget: the app is about to refuse to start.
    unawaited(_report(certSha: cert, apkSha: null, reason: "cert_mismatch"));
    return false;
  }

  /// Runtime check (after boot and on the random interval). Re-confirms the
  /// certificate and compares the on-disk APK against the published hash.
  Future<void> runCheck() async {
    if (!kIsAndroid) return;

    final cert = await _certHash();
    if (expectedCertSha256.isNotEmpty &&
        cert != null &&
        cert != expectedCertSha256) {
      verdict.value = IntegrityVerdict.bricked;
      await _report(certSha: cert, apkSha: null, reason: "cert_mismatch");
      return;
    }

    final published = await _fetchPublishedHash();
    if (published == null) return; // offline / GitHub down -> don't lock
    final apk = await _apkHash();
    if (apk == null) return;

    if (apk != published) {
      verdict.value = IntegrityVerdict.walletLocked;
      await _report(certSha: cert, apkSha: apk, reason: "apk_mismatch");
    } else if (verdict.value == IntegrityVerdict.walletLocked) {
      // Recovered (e.g. the genuine APK was reinstalled).
      verdict.value = IntegrityVerdict.ok;
    }
  }

  /// Start the runtime monitor: one check now, then again at a random interval
  /// between 1 and 10 minutes, repeating for the life of the process.
  void startMonitor() {
    if (!kIsAndroid) return;
    unawaited(runCheck());
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    final minutes = 1 + _rng.nextInt(10); // 1..10 inclusive
    _timer = Timer(Duration(minutes: minutes), () async {
      await runCheck();
      _schedule();
    });
  }

  Future<String?> _fetchPublishedHash() async {
    try {
      final res = await Dio()
          .get<String>(
            apkHashUrl,
            options: Options(
              responseType: ResponseType.plain,
              sendTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ),
          )
          .timeout(const Duration(seconds: 12));
      final body = res.data;
      if (body == null || body.isEmpty) return null;
      // The .sha256 file is "<hash>  DeeMusiq.apk" or just "<hash>".
      final first = body.trim().split(RegExp(r'\s+')).first;
      final norm = _normalizeHash(first);
      return norm.length == 64 ? norm : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _report({
    required String? certSha,
    required String? apkSha,
    required String reason,
  }) async {
    final base = PaymentGatewayConfig.backendBaseUrl;
    if (base.isEmpty) return;
    try {
      await Dio().post(
        "$base/integrity/report",
        data: {
          "deviceId": WalletApiClient.instance.deviceId,
          "reason": reason,
          if (certSha != null) "certSha256": certSha,
          if (apkSha != null) "apkSha256": apkSha,
          "expectedCert": expectedCertSha256,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
    } catch (_) {
      // Best-effort telemetry; never block the app on a failed report.
    }
  }
}
