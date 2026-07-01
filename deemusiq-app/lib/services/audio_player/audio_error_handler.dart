import 'dart:async';

import 'package:deemusiq/services/logger/logger.dart';

/// Centralized error handler for the audio pipeline.
///
/// Every error in the audio pipeline flows through here so we can:
/// - Log what failed and why
/// - Attempt recovery (retry with backoff, skip track, degrade quality)
/// - Notify the user with a clear message (never silently fail)
/// - Never crash the app
class AudioErrorHandler {
  AudioErrorHandler._();

  static final _instance = AudioErrorHandler._();
  static AudioErrorHandler get instance => _instance;

  /// Callback invoked when the user should be shown a message.
  /// Set this from the UI layer (e.g., to show a toast/snackbar).
  void Function(String message, AudioErrorSeverity severity)? onUserMessage;

  /// Callback invoked when the player should skip to the next track
  /// because the current one is unplayable.
  void Function()? onSkipRequested;

  /// Callback invoked when playback should be retried on the current source.
  Future<bool> Function()? onRetryPlayback;

  /// Maps error types to user-friendly messages.
  static String userMessageFor(
    Object error,
    AudioErrorCategory category,
  ) {
    // Network / connectivity errors
    if (category == AudioErrorCategory.network) {
      final s = error.toString().toLowerCase();
      if (s.contains('timeout') || s.contains('timed out')) {
        return 'Connection timed out — retrying...';
      }
      if (s.contains('refused') || s.contains('reset')) {
        return 'Connection refused — trying another source...';
      }
      if (s.contains('no internet') ||
          s.contains('host') ||
          s.contains('resolve') ||
          s.contains('dns')) {
        return 'No internet connection — please check your network';
      }
      return 'Network error — retrying...';
    }

    // Stream / source errors
    if (category == AudioErrorCategory.source) {
      final s = error.toString().toLowerCase();
      if (s.contains('403') || s.contains('forbidden')) {
        return 'This track is unavailable — skipping to next';
      }
      if (s.contains('404') || s.contains('not found')) {
        return 'Track not found — skipping to next';
      }
      if (s.contains('410') || s.contains('gone')) {
        return 'This track has been removed — skipping to next';
      }
      if (s.contains('429') || s.contains('too many')) {
        return 'Rate limited — waiting before retrying...';
      }
      if (s.contains('drm') || s.contains('protected') || s.contains('encrypted')) {
        return 'This track is protected and cannot be played';
      }
      if (s.contains('corrupt') || s.contains('invalid') || s.contains('decode')) {
        return 'Track file appears to be corrupt — skipping to next';
      }
      return 'Unable to play this track — trying next source...';
    }

    // Player / mpv errors
    if (category == AudioErrorCategory.player) {
      final s = error.toString().toLowerCase();
      if (s.contains('init') || s.contains('load') || s.contains('library')) {
        return 'Audio engine failed to start — please restart the app';
      }
      if (s.contains('device') || s.contains('output')) {
        return 'Audio output error — check your speakers or headphones';
      }
      if (s.contains('format') || s.contains('codec') || s.contains('unsupported')) {
        return 'Unsupported audio format — skipping to next';
      }
      return 'Playback error — retrying...';
    }

    return 'Something went wrong — please try again';
  }

  /// Determines the category of an error based on its type and message.
  static AudioErrorCategory _categorize(Object error) {
    final s = error.toString().toLowerCase();

    // Network errors
    if (s.contains('timeout') ||
        s.contains('timed out') ||
        s.contains('connection') ||
        s.contains('network') ||
        s.contains('socket') ||
        s.contains('host') ||
        s.contains('resolve') ||
        s.contains('dns') ||
        s.contains('no internet') ||
        s.contains('refused') ||
        s.contains('reset') ||
        s.contains('unreachable') ||
        error is TimeoutException) {
      return AudioErrorCategory.network;
    }

    // Source / HTTP errors
    if (s.contains('403') ||
        s.contains('404') ||
        s.contains('410') ||
        s.contains('429') ||
        s.contains('500') ||
        s.contains('502') ||
        s.contains('503') ||
        s.contains('forbidden') ||
        s.contains('not found') ||
        s.contains('gone') ||
        s.contains('drm') ||
        s.contains('protected') ||
        s.contains('encrypted') ||
        s.contains('corrupt') ||
        s.contains('decode')) {
      return AudioErrorCategory.source;
    }

    // Player errors
    if (s.contains('mpv') ||
        s.contains('player') ||
        s.contains('playback') ||
        s.contains('init') ||
        s.contains('load') ||
        s.contains('library') ||
        s.contains('device') ||
        s.contains('output') ||
        s.contains('format') ||
        s.contains('codec') ||
        s.contains('unsupported')) {
      return AudioErrorCategory.player;
    }

    return AudioErrorCategory.unknown;
  }

  /// Handles an audio pipeline error: logs it, notifies user, attempts recovery.
  ///
  /// Returns `true` if recovery was attempted and the caller should not
  /// propagate the error further.
  Future<bool> handleError(
    Object error,
    StackTrace stack, {
    String context = '',
    int attempt = 1,
    int maxRetries = 3,
    bool canSkipTrack = true,
  }) async {
    final category = _categorize(error);
    final message = userMessageFor(error, category);

    // Always log
    AppLogger.log.e(
      '[AudioError] $context — $message (${category.name}) — attempt $attempt/$maxRetries',
    );
    AppLogger.reportError(
      error,
      stack,
      '[AudioError] $context',
    );

    // Always notify user
    _notifyUser(message, category.toSeverity());

    // Attempt recovery based on category
    switch (category) {
      case AudioErrorCategory.network:
        return await _recoverNetwork(error, attempt, maxRetries);

      case AudioErrorCategory.source:
        if (canSkipTrack) {
          _notifyUser('Switching to next track...', AudioErrorSeverity.info);
          onSkipRequested?.call();
          return true;
        }
        return false;

      case AudioErrorCategory.player:
        if (attempt < maxRetries) {
          final retryOk = await _retryWithBackoff(attempt, maxRetries);
          if (retryOk) {
            final success = await onRetryPlayback?.call() ?? false;
            if (success) {
              _notifyUser('Playback restored', AudioErrorSeverity.info);
              return true;
            }
          }
        }
        _notifyUser(
          'Audio engine error — please restart the app if this persists',
          AudioErrorSeverity.error,
        );
        return false;

      case AudioErrorCategory.unknown:
        if (attempt < maxRetries) {
          return await _retryWithBackoff(attempt, maxRetries);
        }
        return false;
    }
  }

  Future<bool> _recoverNetwork(
    Object error,
    int attempt,
    int maxRetries,
  ) async {
    if (attempt >= maxRetries) return false;

    final success = await _retryWithBackoff(attempt, maxRetries);
    if (success) {
      final retryOk = await onRetryPlayback?.call() ?? false;
      if (retryOk) return true;
    }
    return false;
  }

  /// Delays with exponential backoff and returns `true` if the delay completed.
  Future<bool> _retryWithBackoff(int attempt, int maxRetries) async {
    try {
      final backoff = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
      // Clamp to max 16 seconds
      final delay =
          backoff > const Duration(seconds: 16)
              ? const Duration(seconds: 16)
              : backoff;
      _notifyUser(
        'Retrying in ${delay.inSeconds}s... (${attempt + 1}/$maxRetries)',
        AudioErrorSeverity.warning,
      );
      await Future.delayed(delay);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _notifyUser(String message, AudioErrorSeverity severity) {
    onUserMessage?.call(message, severity);
  }

  void dispose() {
    onUserMessage = null;
    onSkipRequested = null;
    onRetryPlayback = null;
  }
}

enum AudioErrorCategory {
  network,
  source,
  player,
  unknown;

  AudioErrorSeverity toSeverity() {
    switch (this) {
      case AudioErrorCategory.network:
        return AudioErrorSeverity.warning;
      case AudioErrorCategory.source:
        return AudioErrorSeverity.info;
      case AudioErrorCategory.player:
        return AudioErrorSeverity.error;
      case AudioErrorCategory.unknown:
        return AudioErrorSeverity.error;
    }
  }
}

enum AudioErrorSeverity {
  info,
  warning,
  error,
}
