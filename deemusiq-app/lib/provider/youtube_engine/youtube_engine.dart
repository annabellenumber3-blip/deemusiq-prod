import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:deemusiq/models/database/database.dart';
import 'package:deemusiq/provider/user_preferences/user_preferences_provider.dart';
import 'package:deemusiq/services/youtube_engine/newpipe_engine.dart';
import 'package:deemusiq/services/youtube_engine/youtube_explode_engine.dart';
import 'package:deemusiq/services/youtube_engine/yt_dlp_engine.dart';
import 'package:deemusiq/services/youtube_engine/youtube_engine.dart';

final youtubeEngineProvider = Provider((ref) {
  final engineMode = ref.watch(
    userPreferencesProvider.select((value) => value.youtubeClientEngine),
  );

  if (engineMode == YoutubeClientEngine.newPipe &&
      NewPipeEngine.isAvailableForPlatform) {
    return NewPipeEngine();
  } else if (engineMode == YoutubeClientEngine.ytDlp &&
      YtDlpEngine.isAvailableForPlatform) {
    return YtDlpEngine();
  } else {
    return YouTubeExplodeEngine();
  }
});

/// All available YouTube engines ordered by user preference (selected first).
/// Used by EngineFailover to try alternatives when the primary engine fails.
final allYouTubeEnginesProvider = Provider<List<YouTubeEngine>>((ref) {
  final primary = ref.watch(youtubeEngineProvider);
  final all = <YouTubeEngine>[primary];
  // Add the other engines in fallback order
  if (primary is! YouTubeExplodeEngine) {
    all.add(YouTubeExplodeEngine());
  }
  if (primary is! YtDlpEngine && YtDlpEngine.isAvailableForPlatform) {
    all.add(YtDlpEngine());
  }
  if (primary is! NewPipeEngine && NewPipeEngine.isAvailableForPlatform) {
    all.add(NewPipeEngine());
  }
  return all;
});
