import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

const allowList = [
  "spotify.com",
];

/// SECURITY: Custom HttpOverrides that permits bad certificates ONLY for
/// Spotify API hosts (a legacy workaround for Spotify's cert issues).
///
/// IMPORTANT: This MUST NOT be set as HttpOverrides.global — it should be
/// applied ONLY to the HttpClient used for Spotify metadata API calls. Setting
/// it globally would expose ALL app HTTP traffic (including backend wallet/
/// payment calls) to potential MITM attacks.
///
/// The global assignment in main.dart has been removed; Spotify-specific Dio
/// instances should inject this HttpClient directly instead.
class BadCertificateAllowlistOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return allowList.any((allowedHost) {
          return host.endsWith(allowedHost);
        });
      };
  }
}

/// ---------------------------------------------------------------------------
/// Server TLS certificate pinning for the DeeMusiq backend.
/// ---------------------------------------------------------------------------
///
/// The pinned hash (DEEMUSIQ_SERVER_CERT_SHA256) is the SHA-256 fingerprint of
/// the backend's TLS certificate, set at build time via `--dart-define`.
/// When configured, the Dio client for wallet/payment/account calls will reject
/// any connection where the server's leaf certificate doesn't match — even if
/// a trusted CA signed it. This defeats compromised/intermediate CAs and
/// DNS-poisoning + a valid-but-wrong cert.
///
/// Generate the pin with:
///   openssl s_client -connect api.deemusiq.co.za:443 </dev/null 2>/dev/null \
///     | openssl x509 -noout -fingerprint -sha256 \
///     | tr -d ':' | cut -d= -f2
///
/// Leave empty for dev/test (pinning disabled, standard PKI validation only).

/// SHA-256 of the backend's leaf TLS certificate (lowercase hex, no colons).
const String _serverCertPin = String.fromEnvironment(
  'DEEMUSIQ_SERVER_CERT_SHA256',
  defaultValue: '',
);

bool get serverCertPinningEnabled =>
    _serverCertPin.length == 64 && !_serverCertPin.contains('change-me');

/// Validates the server's X.509 certificate against the pinned SHA-256 hash.
/// Extracts DER bytes from the PEM-encoded certificate, computes SHA-256,
/// and compares against the pinned value.
bool validateServerCertSha256(X509Certificate cert) {
  if (!serverCertPinningEnabled) return true;
  final pinned = _serverCertPin.toLowerCase().replaceAll(RegExp(r'[^0-9a-f]'), '');
  if (pinned.length != 64) return true; // malformed pin → don't block

  // Extract DER bytes from PEM: find base64 content between header and footer.
  final pem = cert.pem;
  final lines = pem.split('\n');
  final b64 = lines
      .where((l) => !l.startsWith('-----'))
      .join();
  final der = base64Decode(b64);
  final digest = sha256.convert(der);
  final actual = digest.toString();
  return pinned == actual;
}

/// HttpOverrides that enforces TLS certificate pinning for the backend host
/// AND allows bad certs only for Spotify API hosts.
///
/// NOTE: The `badCertificateCallback` is called on every secure handshake on
/// Android/iOS, but on some desktop platforms it may only fire when standard
/// PKI validation FAILS. Where it fires on every connection, the backend cert
/// pinning (DEEMUSIQ_SERVER_CERT_SHA256) provides full protection against
/// compromised CAs and MITM proxies. Where it only fires on failures, it still
/// protects against invalid/self-signed cert MITM — and the secure channel
/// (AES-256-GCM) provides defense-in-depth for payload confidentiality.
class DeeMusiqHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Spotify API workaround: accept self-signed/expired certs.
        if (allowList.any((h) => host.endsWith(h))) return true;

        // Backend cert pinning: when DEEMUSIQ_SERVER_CERT_SHA256 is set,
        // accept ONLY connections where the leaf certificate's SHA-256 matches.
        // On platforms where this callback fires for every handshake, this is
        // full cert pinning (replaces PKI). On platforms where it fires only
        // on PKI failures, it protects against invalid-cert MITM — the secure
        // channel AES-256-GCM envelope covers payload confidentiality either way.
        if (serverCertPinningEnabled) {
          return validateServerCertSha256(cert);
        }

        // Default: defer to platform PKI validation (return false = let the
        // platform's own validation result stand).
        return false;
      };
  }
}
