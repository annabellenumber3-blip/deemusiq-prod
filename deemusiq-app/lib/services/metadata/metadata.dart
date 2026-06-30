import 'package:pub_semver/pub_semver.dart';

import 'package:deemusiq/models/metadata/metadata.dart';
import 'package:deemusiq/services/metadata/deemusiq_native_plugin.dart';
import 'package:deemusiq/services/metadata/endpoints/album.dart';
import 'package:deemusiq/services/metadata/endpoints/artist.dart';
import 'package:deemusiq/services/metadata/endpoints/audio_source.dart';
import 'package:deemusiq/services/metadata/endpoints/auth.dart';
import 'package:deemusiq/services/metadata/endpoints/browse.dart';
import 'package:deemusiq/services/metadata/endpoints/playlist.dart';
import 'package:deemusiq/services/metadata/endpoints/search.dart';
import 'package:deemusiq/services/metadata/endpoints/track.dart';
import 'package:deemusiq/services/metadata/endpoints/core.dart';
import 'package:deemusiq/services/metadata/endpoints/user.dart';
import 'package:deemusiq/services/youtube_engine/youtube_engine.dart';

const defaultMetadataLimit = "20";

class MetadataPlugin {
  static final pluginApiVersion = Version.parse("2.0.0");

  late final MetadataAuthEndpoint auth;

  late final MetadataPluginAudioSourceEndpoint audioSource;
  late final MetadataPluginAlbumEndpoint album;
  late final MetadataPluginArtistEndpoint artist;
  late final MetadataPluginBrowseEndpoint browse;
  late final MetadataPluginSearchEndpoint search;
  late final MetadataPluginPlaylistEndpoint playlist;
  late final MetadataPluginTrackEndpoint track;
  late final MetadataPluginUserEndpoint user;
  late final MetadataPluginCore core;

  /// DeeMusiq's built-in metadata provider: every endpoint is native Dart
  /// talking to the DeeMusiq backend `/metadata` API (no Spotify, no Hetu
  /// bytecode). This is what the app uses by default.
  MetadataPlugin.native(YouTubeEngine youtubeEngine) {
    final n = DeeMusiqNativeEndpoints(youtubeEngine);
    auth = n.auth;
    audioSource = n.audioSource;
    artist = n.artist;
    album = n.album;
    browse = n.browse;
    search = n.search;
    playlist = n.playlist;
    track = n.track;
    user = n.user;
    core = n.core;
  }
}
