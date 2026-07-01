import 'dart:async';

import 'package:deemusiq/services/logger/logger.dart';
import 'package:deemusiq/services/connectivity/connection_checker.dart';
import 'package:deemusiq/services/youtube_engine/youtube_engine.dart';

/// Wraps YouTube engine calls with automatic failover and retry logic.
///
/// ## Failover order
/// 1. youtube_explode_dart (primary — fastest, best quality)
/// 2. yt-dlp (fallback 1 — broad compatibility)
/// 3. NewPipe extractor (fallback 2 — lightweight)
///
/// ## Retry logic
/// - Each engine is retried up to [maxRetries] times with exponential
///   backoff (1s → 2s → 4s → 8s → 16s).
/// - Before any attempt, checks internet connectivity via [ConnectionChecker].
///   If no internet, fails immediately with a clear message.
/// - On each failure, calls [onRetry] callback for UI feedback.
///
/// ## Usage
/// ```dart
/// final result = await EngineFailover.tryEngines(
///   engines: [youtubeExplode, ytDlp, newPipe],
///   operation: (engine) => engine.getStreamManifest(videoId),
///   onRetry: (msg, attempt) => showToast(msg),
/// );
/// ```
class EngineFailover {
  EngineFailover._();

  static const maxRetries = 5;
  static const _backoffBase = Duration(seconds: 1);

  /// Tries [operation] on each engine in [engines] sequentially. If an engine
  /// fails, moves to the next one. Each engine is retried up to
  /// [maxRetries] times with exponential backoff.
  ///
  /// Returns the first successful result, or throws [EngineFailoverException]
  /// if all engines + retries are exhausted.
  static Future<T> tryEngines<T>({
    required List<YouTubeEngine> engines,
    required Future<T> Function(YouTubeEngine engine) operation,
    void Function(String message, int attempt)? onRetry,
  }) async {
    // Check internet first
    final conn = await ConnectionChecker.instance.check();
    if (!conn.hasInternet) {
      AppLogger.log.w('EngineFailover: no internet connection — aborting');
      throw EngineFailoverException(
        'Sorry, no internet',
        isNoInternet: true,
      );
    }

    final errors = <String>[];

    for (final engine in engines) {
      AppLogger.log.i('EngineFailover: trying ${engine.runtimeType}...');
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final result = await operation(engine).timeout(
            const Duration(seconds: 30),
          );
          AppLogger.log.i(
            'EngineFailover: success on ${engine.runtimeType} attempt $attempt',
          );
          return result;
        } catch (e) {
          final msg = 'Bad connection, retrying... (attempt $attempt/$maxRetries)';
          AppLogger.log.w(
            'EngineFailover: ${engine.runtimeType} attempt $attempt failed: $e',
          );
          onRetry?.call(msg, attempt);

          if (attempt < maxRetries) {
            // Exponential backoff: 1s, 2s, 4s, 8s, 16s
            await Future.delayed(_backoffBase * (1 << (attempt - 1)));
          } else {
            errors.add('${engine.runtimeType}: ${_shortError(e)}');
          }
        }
      }
    }

    AppLogger.log.e(
      'EngineFailover: all engines exhausted. Errors: ${errors.join(" | ")}',
    );
    throw EngineFailoverException(
      'Something went wrong — please try again later',
      errors: errors,
    );
  }

  static String _shortError(Object e) {
    final s = e.toString();
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }
}

class EngineFailoverException implements Exception {
  final String message;
  final bool isNoInternet;
  final List<String> errors;

  EngineFailoverException(
    this.message, {
    this.isNoInternet = false,
    this.errors = const [],
  });

  @override
  String toString() => message;
}
