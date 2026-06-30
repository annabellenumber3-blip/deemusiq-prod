import 'dart:convert';

import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:deemusiq/services/wallet/secure_channel.dart';
import 'package:deemusiq/services/wallet/payment_service.dart'
    show PaymentGatewayConfig;
import 'package:crypto/crypto.dart' as crypto;

/// Anonymous data sync service for liked songs and playlists.
///
/// All data is anonymized before syncing:
/// - Song IDs are SHA-256 hashed before sending (only hashes are stored server-side)
/// - Playlist names are encrypted with the secure channel key before transmission
/// - No personal information is ever included
///
/// Communication with the backend is encrypted via the secure channel
/// (AES-256-GCM) when configured.
class DataSyncService {
  DataSyncService._();
  static final DataSyncService instance = DataSyncService._();

  bool get isConfigured =>
      PaymentGatewayConfig.backendBaseUrl.isNotEmpty;

  /// Hash a song/track ID using SHA-256. The raw ID never leaves the device.
  static final _sha256 = Sha256();

  static String hashSongId(String songId) {
    final bytes = utf8.encode(songId);
    final hash = crypto.sha256.convert(bytes);
    return hash.toString();
  }

  /// Convert bytes to lowercase hex string.
  static String hexFromBytes(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  // ── Liked Songs ──────────────────────────────────────────────────────────

  /// Sync a liked song to the backend (idempotent).
  Future<void> likeSong(String songId) async {
    if (!isConfigured) return;
    try {
      await WalletApiClient.instance.syncLikeSong(hashSongId(songId));
    } on WalletApiException {
      // Silently fail — liked songs sync is best-effort.
    }
  }

  /// Remove a liked song from the backend.
  Future<void> unlikeSong(String songId) async {
    if (!isConfigured) return;
    try {
      await WalletApiClient.instance.syncUnlikeSong(hashSongId(songId));
    } on WalletApiException {
      // Silently fail.
    }
  }

  /// Fetch all liked song hashes from the backend.
  Future<List<String>> fetchLikedSongs() async {
    if (!isConfigured) return [];
    try {
      return await WalletApiClient.instance.syncFetchLikedSongs();
    } on WalletApiException {
      return [];
    }
  }

  // ── User Playlists ───────────────────────────────────────────────────────

  /// Create a new playlist on the backend.
  /// [name] is plaintext on-device; transmitted encrypted via secure channel.
  /// [songIds] are raw IDs; they are SHA-256 hashed before sending.
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    required List<String> songIds,
  }) async {
    if (!isConfigured) {
      return {'id': '', 'name': name, 'songHashes': []};
    }
    final hashes = songIds.map(hashSongId).toList();
    return await WalletApiClient.instance.syncCreatePlaylist(
      name: name,
      songHashes: hashes,
    );
  }

  /// Update a playlist (name and/or song list).
  Future<void> updatePlaylist({
    required String id,
    String? name,
    List<String>? songIds,
  }) async {
    if (!isConfigured) return;
    final hashes = songIds?.map(hashSongId).toList();
    try {
      await WalletApiClient.instance.syncUpdatePlaylist(
        id: id,
        name: name,
        songHashes: hashes,
      );
    } on WalletApiException {
      // Silently fail.
    }
  }

  /// Delete a playlist from the backend.
  Future<void> deletePlaylist(String id) async {
    if (!isConfigured) return;
    try {
      await WalletApiClient.instance.syncDeletePlaylist(id);
    } on WalletApiException {
      // Silently fail.
    }
  }

  /// Fetch all user playlists from the backend.
  Future<List<Map<String, dynamic>>> fetchPlaylists() async {
    if (!isConfigured) return [];
    try {
      return await WalletApiClient.instance.syncFetchPlaylists();
    } on WalletApiException {
      return [];
    }
  }
}
