import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:deemusiq/services/kv_store/kv_store.dart';
import 'package:deemusiq/services/kv_store/encrypted_kv_store.dart';
import 'package:deemusiq/services/logger/logger.dart';

/// Offline-song DRM: encrypts downloaded audio so files are only playable
/// inside the DeeMusiq app. Uses AES-256-CBC with a device-bound key stored
/// in the platform encrypted key-value store (Android Keystore / iOS Keychain).
/// Without the key, the raw file is useless noise.
///
/// ## Threat model
/// - A rooted device that dumps the KV store and raw files can still decrypt.
///   This is a casual-protection layer, not unbreakable DRM (that needs
///   hardware-backed keystores + Widevine, which require Play Store).
/// - The deposit address for crypto top-ups is *never* in the app (owned by
///   the backend), so a repackaged copy can't steal user funds.
/// - Encrypted files carry a `.deemusiq` extension — the OS media scanner
///   ignores them, keeping them invisible to other music players.
class OfflineTrackEncryption {
  OfflineTrackEncryption._();
  static final OfflineTrackEncryption instance = OfflineTrackEncryption._();

  static const _keyAlias = 'deemusiq_offline_drm_key';
  static const _encryptedExtension = '.deemusiq';

  enc.Key? _cachedKey;
  enc.IV? _cachedIV;

  /// Derives or retrieves the device-bound AES-256 key + IV. Generated once
  /// per install and stored in the platform encrypted key-value store
  /// (flutter_secure_storage — Android Keystore / iOS Keychain).
  /// If wiped (reinstall), previously downloaded files become unreadable —
  /// re-download them.
  Future<enc.Key> _key() async {
    if (_cachedKey != null) return _cachedKey!;

    final secureStorage = EncryptedKvStoreService.storage;
    final existing = await secureStorage.read(key: _keyAlias);
    if (existing != null && existing.length >= 44) {
      try {
        final decoded = base64Decode(existing);
        _cachedKey = enc.Key(decoded.sublist(0, 32));
        _cachedIV = enc.IV(decoded.sublist(32, 48));
        return _cachedKey!;
      } catch (_) {
        // Corrupt stored key — regenerate
      }
    }

    // First run: generate a fresh random key + IV
    final keyBytes = _secureBytes(32);
    final ivBytes = _secureBytes(16);
    _cachedKey = enc.Key(keyBytes);
    _cachedIV = enc.IV(ivBytes);

    final combined = Uint8List(48);
    combined.setAll(0, keyBytes);
    combined.setAll(32, ivBytes);
    await secureStorage.write(key: _keyAlias, value: base64Encode(combined));

    return _cachedKey!;
  }

  Future<enc.IV> _iv() async {
    if (_cachedIV != null) return _cachedIV!;
    await _key();
    return _cachedIV!;
  }

  /// Encrypts [plainBytes] and writes to [outputPath] (appending `.deemusiq`).
  ///
  /// SECURITY: [outputPath] is sanitized against path-traversal attacks.
  /// Only the base filename is used — any directory components are stripped.
  /// The file is always written to the app's download directory.
  Future<String> encryptAndSave(Uint8List plainBytes, String outputPath) async {
    final key = await _key();
    final iv = await _iv();

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    // Sanitize the output path against path traversal: extract only the base
    // filename (basename) and discard any directory components. This prevents
    // a malicious track metadata entry like "../../../etc/passwd" from writing
    // outside the intended download directory.
    final safeName = _sanitizeFileName(outputPath);
    final path = safeName.endsWith(_encryptedExtension)
        ? safeName
        : '$safeName$_encryptedExtension';

    await File(path).writeAsBytes(encrypted.bytes);
    AppLogger.log.i('Encrypted offline track: $path');
    return path;
  }

  /// Strips path traversal sequences and returns only a safe base filename.
  /// - Removes any leading directory components (../ or absolute paths)
  /// - Strips null bytes, control characters, and shell metacharacters
  /// - Falls back to a random name if the result is empty
  static String _sanitizeFileName(String path) {
    // Split on any path separator and take only the last component.
    final segments = path.split(RegExp(r'[/\\]'));
    var name = segments.last;

    // Strip null bytes (used in path-traversal bypasses).
    name = name.replaceAll('\x00', '');

    // Strip control characters and non-printable characters.
    name = name.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');

    // If sanitization leaves an empty or whitespace-only name, use a UUID.
    if (name.trim().isEmpty) {
      name = 'track_${DateTime.now().millisecondsSinceEpoch}.audio';
    }

    return name;
  }

  /// Decrypts a `.deemusiq` file and returns raw audio bytes.
  Future<Uint8List> decrypt(String encryptedPath) async {
    final file = File(encryptedPath);
    if (!await file.exists()) {
      throw OfflineTrackDecryptException('File not found: $encryptedPath');
    }

    final raw = await file.readAsBytes();
    if (raw.length < 16) {
      throw OfflineTrackDecryptException('File too short: $encryptedPath');
    }

    final key = await _key();
    final iv = await _iv();

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    try {
      final decrypted = encrypter.decryptBytes(enc.Encrypted(raw), iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw OfflineTrackDecryptException(
        'Decryption failed — file may be corrupted or tampered: $encryptedPath',
      );
    }
  }

  bool isEncryptedTrack(String path) => path.endsWith(_encryptedExtension);

  void clearCache() {
    _cachedKey = null;
    _cachedIV = null;
  }

  static Uint8List _secureBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }
}

class OfflineTrackDecryptException implements Exception {
  final String message;
  OfflineTrackDecryptException(this.message);
  @override
  String toString() => 'OfflineTrackDecryptException: $message';
}
