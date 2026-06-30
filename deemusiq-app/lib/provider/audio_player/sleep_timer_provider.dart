import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/services/sleep_timer/sleep_timer.dart';

/// Reactive state for the sleep timer so the UI can observe it.
class SleepTimerState {
  final bool isActive;
  final Duration remaining;

  const SleepTimerState({
    required this.isActive,
    required this.remaining,
  });

  static const initial = SleepTimerState(isActive: false, remaining: Duration.zero);
}

/// Provider that exposes the sleep timer as reactive state.
/// Polls the [SleepTimerService] every second while active.
///
/// Usage:
/// ```dart
/// final timerState = ref.watch(sleepTimerProvider);
/// // timerState.isActive, timerState.remaining
/// ref.read(sleepTimerProvider.notifier).start(Duration(minutes: 30));
/// ref.read(sleepTimerProvider.notifier).cancel();
/// ```
class SleepTimerNotifier extends Notifier<SleepTimerState> {
  Timer? _pollTimer;

  @override
  SleepTimerState build() {
    ref.onDispose(() => _pollTimer?.cancel());
    return SleepTimerState.initial;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!SleepTimerService.instance.isActive) {
        _pollTimer?.cancel();
        state = SleepTimerState.initial;
        return;
      }
      state = SleepTimerState(
        isActive: true,
        remaining: SleepTimerService.instance.remaining,
      );
    });
  }

  /// Start the sleep timer for [duration].
  void start(Duration duration) {
    SleepTimerService.instance.start(duration);
    state = SleepTimerState(
      isActive: true,
      remaining: duration,
    );
    _startPolling();
  }

  /// Cancel the sleep timer.
  void cancel() {
    SleepTimerService.instance.cancel();
    _pollTimer?.cancel();
    state = SleepTimerState.initial;
  }

  /// Extend an active timer, or start one if not active.
  void extend(Duration additional) {
    SleepTimerService.instance.extend(additional);
    state = SleepTimerState(
      isActive: SleepTimerService.instance.isActive,
      remaining: SleepTimerService.instance.remaining,
    );
    if (SleepTimerService.instance.isActive) {
      _startPolling();
    }
  }
}

final sleepTimerProvider =
    NotifierProvider<SleepTimerNotifier, SleepTimerState>(
  SleepTimerNotifier.new,
);
