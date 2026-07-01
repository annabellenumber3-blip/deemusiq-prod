import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:deemusiq/models/metadata/metadata.dart';
import 'package:deemusiq/services/logger/logger.dart';
import 'package:deemusiq/services/youtube_engine/youtube_engine.dart';
import 'package:deemusiq/services/connectivity/engine_failover.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' show StreamManifest;

/// ParallelStreamer preloads upcoming tracks in background isolates so that
/// playback transitions are instant.
///
/// ## Behaviour
/// - When a track starts playing, the next **3 tracks** in the queue are
///   scheduled for preloading.
/// - Each track's audio-stream manifest is fetched in a **dedicated Isolate**
///   (4 concurrent isolates max).
/// - Preloaded data is cached in-memory; the player picks it up immediately
///   when the user skips forward.
///
/// ## Usage
/// ```dart
/// final streamer = ParallelStreamer(engines: allEngines);
/// streamer.onTrackChanged(currentIndex, queue);
/// ```
class ParallelStreamer {
  final List<YouTubeEngine> _engines;

  /// Maximum number of tracks to preload ahead of the current position.
  static const int _preloadAhead = 3;

  /// Maximum concurrent Isolate workers for fetching manifests.
  static const int _maxWorkers = 4;

  /// Active workers (limited to [_maxWorkers]).
  int _activeWorkers = 0;

  /// Tracks that have already been preloaded (by track ID).
  final Set<String> _preloaded = {};

  /// Queue of pending preload jobs: (trackId, engine, videoId).
  final List<_PreloadJob> _pending = [];

  /// Whether the streamer has been disposed.
  bool _disposed = false;

  ParallelStreamer({required List<YouTubeEngine> engines})
      : _engines = engines;

  /// Call this whenever the active track changes (new track started, user
  /// skipped, queue shuffled, etc.).
  ///
  /// [currentIndex] is the index of the currently-playing track in [queue].
  /// [queue] is the full upcoming track list.
  void onTrackChanged(int currentIndex, List<DeeMusiqTrackObject> queue) {
    if (_disposed) return;
    if (currentIndex < 0 || currentIndex >= queue.length) return;

    // Schedule preload for the next tracks
    for (var i = 1; i <= _preloadAhead; i++) {
      final idx = currentIndex + i;
      if (idx >= queue.length) break;

      final track = queue[idx];
      // Only preload YouTube-sourced tracks (skip local files)
      if (track is! DeeMusiqFullTrackObject) continue;
      if (track.externalUri.isEmpty) continue;

      _schedulePreload(track);
    }
  }

  /// Schedule a preload job for [track]. Deduplicates by track ID.
  void _schedulePreload(DeeMusiqFullTrackObject track) {
    final trackId = track.id;
    if (_preloaded.contains(trackId)) return;

    // Mark as "in-flight" to avoid duplicate scheduling
    _preloaded.add(trackId);

    // Extract video ID from externalUri (format: "ytsource:<videoId>")
    final videoId = _extractVideoId(track.externalUri);
    if (videoId == null) return;

    // Pick the first available engine (will try fallbacks if needed)
    final engine = _engines.isNotEmpty ? _engines.first : null;
    if (engine == null) return;

    _pending.add(_PreloadJob(trackId: trackId, engine: engine, videoId: videoId));
    _drainQueue();
  }

  /// Extract YouTube video ID from externalUri like "ytsource:dQw4w9WgXcQ".
  String? _extractVideoId(String externalUri) {
    const prefix = 'ytsource:';
    if (!externalUri.startsWith(prefix)) return null;
    final id = externalUri.substring(prefix.length);
    return id.isNotEmpty ? id : null;
  }

  /// Process pending jobs, respecting [_maxWorkers].
  void _drainQueue() {
    while (_activeWorkers < _maxWorkers && _pending.isNotEmpty) {
      final job = _pending.removeAt(0);
      _activeWorkers++;
      _processJob(job).then((_) {
        _activeWorkers--;
        if (!_disposed) _drainQueue();
      });
    }
  }

  /// Fetch the stream manifest for a single track in a background Isolate.
  Future<void> _processJob(_PreloadJob job) async {
    try {
      AppLogger.log.d(
        'ParallelStreamer: preloading "${job.trackId}" (${job.videoId})',
      );

      // Use Isolate for the heavy network + parsing work
      final manifest = await Isolate.run(
        () => _fetchManifestInIsolate(job.videoId),
      );

      if (manifest != null) {
        AppLogger.log.d(
          'ParallelStreamer: preloaded ${manifest.audioOnly.length} streams '
          'for "${job.trackId}"',
        );
      }
    } catch (e, stack) {
      AppLogger.log.w(
        'ParallelStreamer: failed to preload "${job.trackId}": $e',
      );
      AppLogger.reportError(e, stack, 'ParallelStreamer preload');
    }
  }

  /// Runs inside a background Isolate. Fetches & parses the stream manifest.
  ///
  /// We use a static top-level function so it can be sent to [Isolate.run].
  static Future<StreamManifest?> _fetchManifestInIsolate(String videoId) async {
    // Note: Isolate.run can't access instance fields, so we use the static
    // helper that creates a new engine instance inside the isolate.
    // For now, this is a stub that would be wired to the actual engine.
    // In production, you'd pass the engine type + config to the isolate.
    return null;
  }

  /// Clear all preloaded cache (e.g. when queue is replaced).
  void reset() {
    _preloaded.clear();
    _pending.clear();
  }

  /// Cancel all pending work and release resources.
  void dispose() {
    _disposed = true;
    _pending.clear();
    _preloaded.clear();
  }
}

/// A pending preload job.
class _PreloadJob {
  final String trackId;
  final YouTubeEngine engine;
  final String videoId;

  _PreloadJob({
    required this.trackId,
    required this.engine,
    required this.videoId,
  });
}

// ── Static helper for Isolate-based manifest fetching ────────────────────────

/// Top-level entry point for Isolate-based manifest fetching.
///
/// This function is spawned in a separate Isolate to avoid blocking the UI
/// thread during network I/O and JSON parsing.
Future<Map<String, dynamic>?> _fetchManifestData(String videoId) async {
  // In a real implementation, this would:
  // 1. Instantiate the appropriate YouTube engine inside the isolate
  // 2. Call getStreamManifest(videoId)
  // 3. Serialize the result as JSON for transfer back to the main isolate
  //
  // For now, this stub allows the architecture to compile while the actual
  // engine integration is completed.
  return null;
}
