import 'package:deemusiq/services/kv_store/kv_store.dart';
import 'package:deemusiq/services/logger/logger.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// User-selectable YouTube audio bitrate quality levels.
enum YouTubeAudioQuality {
  /// Let the app pick the best available quality (default).
  auto('Auto'),

  /// Low quality — targets ~64 kbps.
  low('Low (64 kbps)'),

  /// Medium quality — targets ~128 kbps.
  medium('Medium (128 kbps)'),

  /// High quality — targets ~256 kbps.
  high('High (256 kbps)');

  final String label;
  const YouTubeAudioQuality(this.label);

  /// Approximate minimum bitrate (bits per second) this quality tier expects.
  int get minBitrate => switch (this) {
        YouTubeAudioQuality.low => 32000,
        YouTubeAudioQuality.medium => 96000,
        YouTubeAudioQuality.high => 192000,
        YouTubeAudioQuality.auto => 0,
      };

  /// Approximate maximum bitrate (bits per second) this quality tier expects.
  int get maxBitrate => switch (this) {
        YouTubeAudioQuality.low => 95999,
        YouTubeAudioQuality.medium => 191999,
        YouTubeAudioQuality.high => 512000,
        YouTubeAudioQuality.auto => 512000,
      };
}

/// Persists and retrieves the user's YouTube audio quality preference.
class YouTubeAudioQualityService {
  static const _key = 'youtubeAudioQuality';

  static YouTubeAudioQuality get quality {
    final raw = KVStoreService.sharedPreferences.getString(_key);
    if (raw == null) return YouTubeAudioQuality.auto;
    return YouTubeAudioQuality.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => YouTubeAudioQuality.auto,
    );
  }

  static Future<void> setQuality(YouTubeAudioQuality quality) async {
    await KVStoreService.sharedPreferences.setString(_key, quality.name);
    AppLogger.log.i('YouTube audio quality set to: ${quality.label}');
  }

  /// Filters a list of [AudioOnlyStreamInfo] down to those that match the
  /// user's selected quality tier. When [quality] is `auto`, returns all
  /// streams unfiltered.
  static Iterable<AudioOnlyStreamInfo> filterStreams(
    Iterable<AudioOnlyStreamInfo> streams, {
    YouTubeAudioQuality? qualityOverride,
  }) {
    final q = qualityOverride ?? quality;
    if (q == YouTubeAudioQuality.auto) {
      AppLogger.log.d('Quality filter: auto mode — keeping all ${streams.length} streams');
      return streams;
    }

    final filtered = streams.where((s) {
      final bps = s.bitrate.bitsPerSecond;
      return bps >= q.minBitrate && bps <= q.maxBitrate;
    }).toList();

    AppLogger.log.i(
      'Quality filter (${q.label}): ${filtered.length}/${streams.length} streams pass '
      '(${q.minBitrate}–${q.maxBitrate} bps)',
    );
    return filtered;
  }
}
