import 'dart:async';

import 'package:deemusiq/services/audio_player/audio_player.dart';
import 'package:deemusiq/services/logger/logger.dart';

/// Manages a sleep timer that stops playback after a configurable duration.
/// Uses [audioPlayer] to pause/stop playback when the timer fires.
class SleepTimerService {
  SleepTimerService._();
  static final SleepTimerService instance = SleepTimerService._();

  Timer? _timer;
  DateTime? _endTime;

  /// Whether the sleep timer is currently active.
  bool get isActive => _timer != null && _timer!.isActive;

  /// The time at which the timer will fire, or null if not active.
  DateTime? get endTime => _endTime;

  /// Remaining duration until the timer fires, or Duration.zero if not active.
  Duration get remaining {
    if (!isActive || _endTime == null) return Duration.zero;
    final diff = _endTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Starts the sleep timer. After [duration], playback will be paused.
  /// If a timer is already running, it will be cancelled and replaced.
  void start(Duration duration) {
    cancel();
    _endTime = DateTime.now().add(duration);
    _timer = Timer(duration, _onTimerFired);
    AppLogger.log.i('Sleep timer started for ${duration.inMinutes} minutes');
  }

  /// Cancels the active sleep timer without pausing playback.
  void cancel() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      _endTime = null;
      AppLogger.log.i('Sleep timer cancelled');
    }
  }

  void _onTimerFired() async {
    AppLogger.log.i('Sleep timer fired — pausing playback');
    try {
      if (audioPlayer.isPlaying) {
        await audioPlayer.pause();
      }
    } catch (e, stack) {
      AppLogger.reportError(e, stack);
    } finally {
      _timer = null;
      _endTime = null;
    }
  }

  /// Extends an active timer by [additional] duration.
  /// If no timer is active, starts one with [additional].
  void extend(Duration additional) {
    if (isActive) {
      final newRemaining = remaining + additional;
      start(newRemaining);
    } else {
      start(additional);
    }
  }
}
