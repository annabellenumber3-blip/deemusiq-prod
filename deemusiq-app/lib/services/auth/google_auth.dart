import 'package:google_sign_in/google_sign_in.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:deemusiq/services/wallet/payment_service.dart'
    show PaymentGatewayConfig;
import 'package:deemusiq/services/wallet/device_identity.dart';
import 'package:deemusiq/services/kv_store/kv_store.dart';
import 'package:deemusiq/services/integrity/integrity_service.dart';
import 'dart:convert';

/// Google OAuth sign-in flow for DeeMusiq.
///
/// Uses the google_sign_in package to obtain an ID token client-side. The ID
/// token is then sent to the DeeMusiq backend's `POST /auth/google` endpoint,
/// which verifies it server-side using google-auth-library and returns a JWT.
///
/// **Privacy**: The backend only stores a SHA-256 hash of the Google `sub`
/// claim. No email, name, or profile data is ever persisted. Liked songs are
/// stored as hashed IDs; playlist names are encrypted.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const _webClientIdKey = 'GOOGLE_WEB_CLIENT_ID';

  /// The Google Web Client ID must be set via dart-define or environment.
  /// This is the OAuth 2.0 client ID from Google Cloud Console (Web application).
  static String get _webClientId =>
      const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');

  /// Whether Google Sign-In is configured. Requires only the backend.
  /// Google OAuth client ID is optional — falls back to device-based auth.
  bool get isConfigured =>
      PaymentGatewayConfig.backendBaseUrl.isNotEmpty;

  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _client {
    _googleSignIn ??= GoogleSignIn(
      clientId: _webClientId,
      // Request only the minimal scope — just an ID token, no access to user data.
      scopes: ['openid'],
    );
    return _googleSignIn!;
  }

  /// Whether a user is currently signed in with Google on this device.
  Future<bool> isSignedIn() async {
    if (!isConfigured) return false;
    try {
      return await _client.isSignedIn();
    } catch (_) {
      return false;
    }
  }

  /// Start the Google Sign-In flow. Returns a backend JWT on success.
  ///
  /// If a Google OAuth client ID is configured, the full OAuth flow runs:
  /// 1. Google Sign-In dialog → obtain ID token
  /// 2. POST /auth/google with the ID token + device ID
  /// 3. Backend verifies the token, creates/links user, returns a JWT
  ///
  /// If no Google client ID is set, falls back to device-based auth:
  /// 1. Gets device identity (Ed25519 keypair)
  /// 2. POST /auth/device/login with signed challenge
  /// 3. Backend returns a JWT
  Future<String> signIn() async {
    if (!isConfigured) {
      throw GoogleAuthException('Sign-in is not configured.');
    }

    // Fallback: device-based auth when no Google client ID is set
    if (_webClientId.isEmpty) {
      final deviceId = await DeviceIdentity.instance.id;
      final res = await WalletApiClient.instance.post(
        '/auth/device/login',
        data: {'deviceId': deviceId},
      );
      if (res['token'] == null) throw GoogleAuthException('Device login failed.');
      return res['token'] as String;
    }

    // Full Google OAuth flow
    // Sign out first to force account selection.
    try {
      await _client.signOut();
    } catch (_) {}

    // Trigger the Google Sign-In dialog.
    final GoogleSignInAccount? googleUser;
    try {
      googleUser = await _client.signIn();
    } catch (e) {
      throw GoogleAuthException('Sign-in was cancelled or failed.');
    }

    if (googleUser == null) {
      throw GoogleAuthException('Sign-in was cancelled.');
    }

    // Obtain the ID token.
    final GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      throw GoogleAuthException('Failed to get authentication token.');
    }

    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw GoogleAuthException('No ID token received from Google.');
    }

    // Send the ID token to the DeeMusiq backend for server-side verification.
    try {
      final token = await WalletApiClient.instance.authWithGoogle(
        idToken: idToken,
        deviceId: WalletApiClient.instance.deviceId,
      );
      return token;
    } on WalletApiException catch (e) {
      throw GoogleAuthException(e.message);
    }
  }

  /// Sign out of Google on this device. Does NOT revoke the backend token.
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } catch (_) {}
    WalletApiClient.instance.logout();
  }

  /// Disconnect Google entirely: sign out + revoke access.
  Future<void> disconnect() async {
    try {
      await _client.disconnect();
    } catch (_) {}
    WalletApiClient.instance.logout();
  }
}

class GoogleAuthException implements Exception {
  final String message;
  GoogleAuthException(this.message);
  @override
  String toString() => 'GoogleAuthException: $message';
}
