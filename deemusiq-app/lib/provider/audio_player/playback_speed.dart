import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/services/audio_player/audio_player.dart';
import 'package:deemusiq/services/logger/logger.dart';
import 'package:deemusiq/services/kv_store/kv_store.dart';

/// Available playback speeds.
const List<double> playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

/// Manages playback speed, persisted across app restarts.
class PlaybackSpeedNotifier extends Notifier<double> {
  static const _speedKey = 'deemusiq_playback_speed';

  @override
  double build() {
    final saved = KVStoreService.sharedPreferences.getDouble(_speedKey);
    final speed = saved ?? 1.0;
    // Apply the saved speed to the audio player
    audioPlayer.setSpeed(speed);
    return speed;
  }

  /// Set the playback speed and persist it.
  Future<void> setSpeed(double speed) async {
    assert(speed >= 0.5 && speed <= 2.0, 'Speed must be between 0.5x and 2.0x');
    state = speed;
    await KVStoreService.sharedPreferences.setDouble(_speedKey, speed);
    await audioPlayer.setSpeed(speed);
    AppLogger.log.i('Playback speed set to ${speed}x');
  }

  /// Reset speed to 1.0x (normal).
  Future<void> reset() => setSpeed(1.0);

  /// Cycle to the next available speed (wraps around).
  Future<void> cycleNext() async {
    final currentIndex = playbackSpeeds.indexOf(state);
    final nextIndex = (currentIndex + 1) % playbackSpeeds.length;
    await setSpeed(playbackSpeeds[nextIndex]);
  }
}

final playbackSpeedProvider =
    NotifierProvider<PlaybackSpeedNotifier, double>(
  PlaybackSpeedNotifier.new,
);
