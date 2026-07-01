import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import 'package:deemusiq/models/metadata/metadata.dart';
import 'package:deemusiq/services/metadata/endpoints/album.dart';
import 'package:deemusiq/services/metadata/endpoints/artist.dart';
import 'package:deemusiq/services/metadata/endpoints/audio_source.dart';
import 'package:deemusiq/services/metadata/endpoints/auth.dart';
import 'package:deemusiq/services/metadata/endpoints/browse.dart';
import 'package:deemusiq/services/metadata/endpoints/core.dart';
import 'package:deemusiq/services/metadata/endpoints/playlist.dart';
import 'package:deemusiq/services/metadata/endpoints/search.dart';
import 'package:deemusiq/services/metadata/endpoints/track.dart';
import 'package:deemusiq/services/metadata/endpoints/user.dart';
import 'package:deemusiq/services/wallet/payment_service.dart'
    show PaymentGatewayConfig;
import 'package:deemusiq/services/youtube_engine/youtube_engine.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' show Video;
import 'package:deemusiq/services/audio_player/audio_quality.dart';
import 'package:deemusiq/services/connectivity/engine_failover.dart';
import 'package:deemusiq/services/connectivity/connection_checker.dart';
import 'package:deemusiq/services/logger/logger.dart';

/// The built-in "plugin" identity DeeMusiq presents in place of any external
/// metadata provider. It carries no bytecode — the endpoints are native Dart
/// (see below) talking to the DeeMusiq backend `/metadata` API.
final PluginConfiguration kDeeMusiqNativePluginConfig = PluginConfiguration(
  name: "DeeMusiq",
  description: "DeeMusiq's own catalog — artists, albums and tracks.",
  version: "1.0.0",
  author: "DeeMusiq",
  entryPoint: "",
  pluginApiVersion: "2.0.0",
  apis: const [],
  abilities: const [
    PluginAbilities.metadata,
    PluginAbilities.audioSource,
  ],
);



// ── Playable-source encoding ─────────────────────────────────────────────────
// Each track carries its audio source in `externalUri` so the audio-source
// endpoint can resolve it without a second lookup.
const _ytPrefix = "ytsource:";
const _urlPrefix = "urlsource:";

String _encodeSource(Map? source) {
  if (source == null) return "";
  switch (source["type"]) {
    case "youtube":
      return "$_ytPrefix${source["youtubeId"]}";
    case "url":
      return "$_urlPrefix${source["url"]}";
    default:
      return "";
  }
}

// ── Backend client ───────────────────────────────────────────────────────────

class _CatalogApi {
  static const _maxRetries = 3;
  static const _baseDelayMs = 500;

  Dio _client() => Dio(
        BaseOptions(
          baseUrl: PaymentGatewayConfig.backendBaseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );

  bool get isConfigured => PaymentGatewayConfig.backendBaseUrl.isNotEmpty;

  /// Returns null if the backend is not configured.
  Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    int attempt = 0;
    if (!isConfigured) {
      AppLogger.log.i('Backend not configured — returning null for $path');
      return null;
    }
    while (true) {
      try {
        final res = await _client().get(path, queryParameters: query);
        return (res.data as Map).cast<String, dynamic>();
      } catch (e, stack) {
        attempt++;
        if (attempt >= _maxRetries) {
          AppLogger.log.w('Catalog API failed after $_maxRetries attempts: $path — ${e.toString()}');
          AppLogger.reportError(e, stack);
          rethrow;
        }
        final delay = Duration(
          milliseconds: _baseDelayMs * pow(2, attempt - 1).toInt() +
              Random().nextInt(200),
        );
        AppLogger.log.w('Catalog API attempt $attempt/$_maxRetries failed: $path — retrying in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }
    }
  }
  // Catalog-specific methods (search, home, artist, album, playlist, track)
  // removed — YouTube is now the primary source for all music discovery.
}

// ── Mappers: backend JSON → app model objects ────────────────────────────────

List<DeeMusiqImageObject> _images(String? url) =>
    url == null || url.isEmpty ? const [] : [DeeMusiqImageObject(url: url)];

DeeMusiqAlbumType _albumType(String? t) {
  switch (t) {
    case "single":
    case "ep":
      return DeeMusiqAlbumType.single;
    case "compilation":
      return DeeMusiqAlbumType.compilation;
    default:
      return DeeMusiqAlbumType.album;
  }
}

DeeMusiqSimpleArtistObject _simpleArtistFromRef(Map a) =>
    DeeMusiqSimpleArtistObject(
      id: (a["id"] ?? "").toString(),
      name: (a["name"] ?? "").toString(),
      externalUri: "deemusiq:artist:${a["id"] ?? ""}",
    );

DeeMusiqFullArtistObject _fullArtist(Map a) => DeeMusiqFullArtistObject(
      id: (a["id"] ?? "").toString(),
      name: (a["name"] ?? "").toString(),
      externalUri: "deemusiq:artist:${a["id"] ?? ""}",
      images: _images(a["imageUrl"] as String?),
    );

DeeMusiqSimpleAlbumObject _simpleAlbum(Map a) {
  final artistRef = a["artist"] as Map?;
  return DeeMusiqSimpleAlbumObject(
    id: (a["id"] ?? "").toString(),
    name: (a["title"] ?? a["name"] ?? "").toString(),
    externalUri: "deemusiq:album:${a["id"] ?? ""}",
    artists: artistRef != null ? [_simpleArtistFromRef(artistRef)] : const [],
    images: _images(a["coverUrl"] as String?),
    albumType: _albumType(a["albumType"] as String?),
    releaseDate: a["releaseDate"]?.toString(),
  );
}

DeeMusiqSimpleAlbumObject _trackAlbum(Map t) {
  final album = t["album"] as Map?;
  final artistRef = t["artist"] as Map?;
  if (album != null) {
    return DeeMusiqSimpleAlbumObject(
      id: (album["id"] ?? "").toString(),
      name: (album["title"] ?? "").toString(),
      externalUri: "deemusiq:album:${album["id"] ?? ""}",
      artists: artistRef != null ? [_simpleArtistFromRef(artistRef)] : const [],
      images: _images((album["coverUrl"] ?? t["coverUrl"]) as String?),
      albumType: DeeMusiqAlbumType.album,
    );
  }
  // Single/loose track: synthesise a one-track album from the track itself.
  return DeeMusiqSimpleAlbumObject(
    id: (t["id"] ?? "").toString(),
    name: (t["title"] ?? "").toString(),
    externalUri: "deemusiq:track:${t["id"] ?? ""}",
    artists: artistRef != null ? [_simpleArtistFromRef(artistRef)] : const [],
    images: _images(t["coverUrl"] as String?),
    albumType: DeeMusiqAlbumType.single,
  );
}

DeeMusiqFullTrackObject _track(Map t) {
  final artistRef = t["artist"] as Map?;
  return DeeMusiqTrackObject.full(
    id: (t["id"] ?? "").toString(),
    name: (t["title"] ?? "").toString(),
    externalUri: _encodeSource(t["source"] as Map?),
    artists: artistRef != null ? [_simpleArtistFromRef(artistRef)] : const [],
    album: _trackAlbum(t),
    durationMs: (t["durationMs"] as num?)?.toInt() ?? 0,
    isrc: "",
    explicit: t["explicit"] == true,
  ) as DeeMusiqFullTrackObject;
}

DeeMusiqUserObject get _deemusiqOwner => DeeMusiqUserObject(
      id: "deemusiq",
      name: "DeeMusiq",
      externalUri: "deemusiq:user:deemusiq",
    );

DeeMusiqSimplePlaylistObject _simplePlaylist(Map p) =>
    DeeMusiqSimplePlaylistObject(
      id: (p["id"] ?? "").toString(),
      name: (p["title"] ?? "").toString(),
      description: (p["description"] ?? "").toString(),
      externalUri: "deemusiq:playlist:${p["id"] ?? ""}",
      owner: _deemusiqOwner,
      images: _images(p["coverUrl"] as String?),
    );

DeeMusiqPaginationResponseObject<T> _page<T>(List<T> items) =>
    DeeMusiqPaginationResponseObject<T>(
      limit: items.length,
      nextOffset: null,
      total: items.length,
      hasMore: false,
      items: items,
    );

List<Map> _list(dynamic v) =>
    (v as List? ?? const []).whereType<Map>().toList();

// ── Shared YouTube helpers ───────────────────────────────────────────────────

/// Maps a YouTube [Video] to a [DeeMusiqFullTrackObject].
DeeMusiqFullTrackObject _videoToTrack(Video video) {
  return DeeMusiqTrackObject.full(
    id: video.id.value,
    name: video.title,
    externalUri: "$_ytPrefix${video.id.value}",
    artists: video.author.isNotEmpty
        ? [
            DeeMusiqSimpleArtistObject(
              id: video.author,
              name: video.author,
              externalUri: "deemusiq:artist:${video.author}",
            )
          ]
        : [],
    album: DeeMusiqSimpleAlbumObject(
      id: video.id.value,
      name: video.title,
      externalUri: "deemusiq:album:${video.id.value}",
      artists: video.author.isNotEmpty
          ? [
              DeeMusiqSimpleArtistObject(
                id: video.author,
                name: video.author,
                externalUri: "deemusiq:artist:${video.author}",
              )
            ]
          : const [],
      images: video.thumbnails.highResUrl.isNotEmpty
          ? [DeeMusiqImageObject(url: video.thumbnails.highResUrl)]
          : const [],
      albumType: DeeMusiqAlbumType.single,
    ),
    durationMs: video.duration?.inMilliseconds ?? 0,
    isrc: "",
    explicit: false,
  ) as DeeMusiqFullTrackObject;
}

/// Searches YouTube for tracks using engine failover.
///
/// Filters out low-quality / junk results:
/// - Titles containing "test", "Test Song", "untitled" (case-insensitive)
/// - Duration < 30 seconds
/// - View count < 1 000
Future<List<DeeMusiqFullTrackObject>> _youtubeTrackSearch(
    List<YouTubeEngine> allEngines, String query, int limit) async {
  try {
    final videos = await EngineFailover.tryEngines(
      engines: allEngines,
      operation: (engine) async {
        final results = await engine.searchVideos(query);
        return results.take(limit * 3).toList(); // fetch more to compensate for filtering
      },
    );

    // ── Quality filter ──────────────────────────────────────────────────
    const junkTitlePatterns = ['test', 'test song', 'untitled'];
    final filtered = videos.where((v) {
      final titleLower = v.title.toLowerCase();

      // Skip junk titles
      if (junkTitlePatterns.any((p) => titleLower.contains(p))) {
        AppLogger.log.d('_youtubeTrackSearch: filtered junk title "${v.title}"');
        return false;
      }

      // Skip very short videos (< 30 seconds, likely clips/shorts)
      final dur = v.duration;
      if (dur != null && dur.inSeconds < 30) {
        AppLogger.log.d(
          '_youtubeTrackSearch: filtered short video "${v.title}" (${dur.inSeconds}s)',
        );
        return false;
      }

      // Skip low-view videos (< 1000 views, likely noise)
      final views = v.engagement.viewCount;
      if (views != null && views < 1000) {
        AppLogger.log.d(
          '_youtubeTrackSearch: filtered low-view video "${v.title}" ($views views)',
        );
        return false;
      }

      return true;
    }).take(limit).toList();

    AppLogger.log.i(
      '_youtubeTrackSearch: ${filtered.length}/${videos.length} results passed quality filter',
    );
    return filtered.map(_videoToTrack).toList();
  } catch (e, stack) {
    AppLogger.log.w('YouTube search failed: ${e.toString()}');
    AppLogger.reportError(e, stack);
    return [];
  }
}

// ── Native endpoints ─────────────────────────────────────────────────────────

class _NativeSearch extends MetadataPluginSearchEndpoint {
  final _CatalogApi api;
  final YouTubeEngine _youtubeEngine;
  final List<YouTubeEngine> _allEngines;
  _NativeSearch(this.api, this._youtubeEngine, this._allEngines) : super();

  @override
  List<String> get chips => const ["all", "tracks", "artists", "albums", "playlists"];

  @override
  Future<DeeMusiqSearchResponseObject> all(String query) async {
    // YouTube is the primary source for all music discovery
    final ytTracks = await _youtubeTrackSearch(_allEngines, query, 20);
    return DeeMusiqSearchResponseObject(
      albums: const [],
      artists: const [],
      playlists: const [],
      tracks: ytTracks,
    );
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> albums(
      String query, {int? limit, int? offset}) async {
    // YouTube doesn't have album category searches
    return _page(const []);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>> artists(
      String query, {int? limit, int? offset}) async {
    // YouTube doesn't have artist category searches
    return _page(const []);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimplePlaylistObject>>
      playlists(String query, {int? limit, int? offset}) async {
    // YouTube doesn't have playlist category searches
    return _page(const []);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
      String query, {int? limit, int? offset}) async {
    final lim = limit ?? 20;
    // YouTube is the primary source for all music discovery
    final ytTracks = await _youtubeTrackSearch(_allEngines, query, lim);
    return _page(ytTracks);
  }
}

class _NativeAlbum extends MetadataPluginAlbumEndpoint {
  final _CatalogApi api;
  final List<YouTubeEngine> _allEngines;
  _NativeAlbum(this.api, this._allEngines) : super();

  @override
  Future<DeeMusiqFullAlbumObject> getAlbum(String id) async {
    // Backend catalog is stripped — return minimal album object
    return DeeMusiqFullAlbumObject(
      id: id,
      name: "Album",
      artists: const [],
      images: const [],
      releaseDate: "",
      externalUri: "deemusiq:album:$id",
      totalTracks: 0,
      albumType: DeeMusiqAlbumType.album,
    );
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
      String id, {int? offset, int? limit}) async {
    // Backend catalog is stripped — no album tracks available
    return _page(const <DeeMusiqFullTrackObject>[]);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> releases(
      {int? offset, int? limit}) async {
    // Use YouTube popular SA music search for new releases
    final ytTracks = await _youtubeTrackSearch(
        _allEngines, "South African music new releases", limit ?? 20);
    final albums = ytTracks.map((t) => t.album).toList();
    return _page(albums);
  }

  @override
  Future<void> save(List<String> ids) async {}
  @override
  Future<void> unsave(List<String> ids) async {}
}

class _NativeArtist extends MetadataPluginArtistEndpoint {
  final _CatalogApi api;
  _NativeArtist(this.api) : super();

  @override
  Future<DeeMusiqFullArtistObject> getArtist(String id) async {
    // Backend catalog is stripped — return minimal artist object
    return DeeMusiqFullArtistObject(
      id: id,
      name: "Artist",
      externalUri: "deemusiq:artist:$id",
      images: const [],
    );
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> topTracks(
      String id, {int? offset, int? limit}) async {
    // Backend catalog is stripped — no top tracks available
    return _page(const <DeeMusiqFullTrackObject>[]);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> albums(
      String id, {int? offset, int? limit}) async {
    // Backend catalog is stripped — no artist albums available
    return _page(const <DeeMusiqSimpleAlbumObject>[]);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>> related(
          String id, {int? offset, int? limit}) async =>
      _page(const []);

  @override
  Future<void> save(List<String> ids) async {}
  @override
  Future<void> unsave(List<String> ids) async {}
}

class _NativePlaylist extends MetadataPluginPlaylistEndpoint {
  final _CatalogApi api;
  _NativePlaylist(this.api) : super();

  @override
  Future<DeeMusiqFullPlaylistObject> getPlaylist(String id) async {
    // Backend catalog is stripped — return minimal playlist object
    return DeeMusiqFullPlaylistObject(
      id: id,
      name: "Playlist",
      description: "",
      externalUri: "deemusiq:playlist:$id",
      owner: _deemusiqOwner,
      images: const [],
    );
  }

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
      String id, {int? offset, int? limit}) async {
    // Backend catalog is stripped — no playlist tracks available
    return _page(const <DeeMusiqFullTrackObject>[]);
  }

  // User-created playlists aren't supported by the catalog backend yet.
  @override
  Future<DeeMusiqFullPlaylistObject?> create(String userId,
          {required String name,
          String? description,
          bool? public,
          bool? collaborative}) async =>
      null;
  @override
  Future<void> update(String playlistId,
      {String? name,
      String? description,
      bool? public,
      bool? collaborative}) async {}
  @override
  Future<void> addTracks(String playlistId,
      {required List<String> trackIds, int? position}) async {}
  @override
  Future<void> removeTracks(String playlistId,
      {required List<String> trackIds}) async {}
  @override
  Future<void> save(String playlistId) async {}
  @override
  Future<void> unsave(String playlistId) async {}
  @override
  Future<void> deletePlaylist(String playlistId) async {}
}

class _NativeTrack extends MetadataPluginTrackEndpoint {
  final _CatalogApi api;
  _NativeTrack(this.api) : super();

  @override
  Future<DeeMusiqFullTrackObject> getTrack(String id) async {
    // Backend catalog is stripped — return minimal track object
    return DeeMusiqTrackObject.full(
      id: id,
      name: "Track",
      externalUri: "",
      artists: const [],
      album: DeeMusiqSimpleAlbumObject(
        id: "",
        name: "",
        externalUri: "",
        artists: const [],
        images: const [],
        albumType: DeeMusiqAlbumType.album,
      ),
      durationMs: 0,
      isrc: "",
      explicit: false,
    ) as DeeMusiqFullTrackObject;
  }

  @override
  Future<List<DeeMusiqFullTrackObject>> radio(String id) async => const [];
  @override
  Future<void> save(List<String> ids) async {}
  @override
  Future<void> unsave(List<String> ids) async {}
}

class _NativeBrowse extends MetadataPluginBrowseEndpoint {
  final _CatalogApi api;
  final List<YouTubeEngine> _allEngines;
  _NativeBrowse(this.api, this._allEngines) : super();

  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqBrowseSectionObject<Object>>>
      sections({int? offset, int? limit}) async {
    // YouTube popular/trending SA music as browse sections
    final sectionQueries = <String, String>{
      "amapiano": "Amapiano 2026",
      "house": "South African House",
      "gqom": "Gqom mixes",
    };
    final sections = <DeeMusiqBrowseSectionObject<Object>>[];
    for (final entry in sectionQueries.entries) {
      final tracks = await _youtubeTrackSearch(
          _allEngines, entry.value, 10);
      if (tracks.isNotEmpty) {
        sections.add(DeeMusiqBrowseSectionObject<Object>(
          id: entry.key,
          title: entry.key[0].toUpperCase() + entry.key.substring(1),
          externalUri: "deemusiq:section:${entry.key}",
          browseMore: false,
          items: tracks,
        ));
      }
    }
    return _page(sections);
  }

  @override
  Future<DeeMusiqPaginationResponseObject<Object>> sectionItems(String id,
          {int? offset, int? limit}) async =>
      _page(const []);
}

class _NativeUser extends MetadataPluginUserEndpoint {
  _NativeUser() : super();

  @override
  Future<DeeMusiqUserObject> me() async => _deemusiqOwner;
  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> savedTracks(
          {int? offset, int? limit}) async =>
      _page(const []);
  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimplePlaylistObject>>
      savedPlaylists({int? offset, int? limit}) async => _page(const []);
  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>>
      savedAlbums({int? offset, int? limit}) async => _page(const []);
  @override
  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>>
      savedArtists({int? offset, int? limit}) async => _page(const []);
  @override
  Future<bool> isSavedPlaylist(String playlistId) async => false;
  @override
  Future<List<bool>> isSavedTracks(List<String> ids) async =>
      List.filled(ids.length, false);
  @override
  Future<List<bool>> isSavedAlbums(List<String> ids) async =>
      List.filled(ids.length, false);
  @override
  Future<List<bool>> isSavedArtists(List<String> ids) async =>
      List.filled(ids.length, false);
}

class _NativeAuth extends MetadataAuthEndpoint {
  _NativeAuth() : super();

  // Typed as raw `Stream` to match the base getter's return type exactly
  // (a `Stream<dynamic>` literal is rejected as an invalid override).
  final Stream _authState = const Stream.empty();

  @override
  Future<void> authenticate() async {}
  @override
  bool isAuthenticated() => true; // no external login — the catalog is public
  @override
  Future<void> logout() async {}
  @override
  Stream get authStateStream => _authState;
}

class _NativeCore extends MetadataPluginCore {
  _NativeCore() : super();

  @override
  Future<PluginUpdateAvailable?> checkUpdate(PluginConfiguration pluginConfig) async =>
      null;
  @override
  Future<String> get support async => "";
  @override
  Future<void> scrobble(Map<String, dynamic> details) async {}
}

class _NativeAudioSource extends MetadataPluginAudioSourceEndpoint {
  final YouTubeEngine youtubeEngine;
  final List<YouTubeEngine> allEngines;
  _NativeAudioSource(this.youtubeEngine, this.allEngines) : super();

  @override
  List<DeeMusiqAudioSourceContainerPreset> get supportedPresets => [
        DeeMusiqAudioSourceContainerPreset.lossy(
          type: DeeMusiqMediaCompressionType.lossy,
          name: "Audio",
          qualities: [
            DeeMusiqAudioLossyContainerQuality(bitrate: 320000),
            DeeMusiqAudioLossyContainerQuality(bitrate: 160000),
            DeeMusiqAudioLossyContainerQuality(bitrate: 96000),
          ],
        ),
      ];

  @override
  Future<List<DeeMusiqAudioSourceMatchObject>> matches(
      DeeMusiqFullTrackObject track) async {
    final uri = track.externalUri;
    AppLogger.log.i('[_NativeAudioSource.matches] track="${track.name}" externalUri="$uri"');
    if (uri.isNotEmpty && uri.startsWith(_ytPrefix)) {
      AppLogger.log.i('[_NativeAudioSource.matches] Using existing ytsource: $uri');
      return [
        DeeMusiqAudioSourceMatchObject(
          id: track.id,
          title: track.name,
          artists: track.artists.map((a) => a.name).toList(),
          duration: Duration(milliseconds: track.durationMs),
          thumbnail: track.album.images.isNotEmpty
              ? track.album.images.first.url
              : null,
          externalUri: uri,
        ),
      ];
    }
    if (uri.isNotEmpty && uri.startsWith(_urlPrefix)) {
      return [
        DeeMusiqAudioSourceMatchObject(
          id: track.id,
          title: track.name,
          artists: track.artists.map((a) => a.name).toList(),
          duration: Duration(milliseconds: track.durationMs),
          thumbnail: track.album.images.isNotEmpty
              ? track.album.images.first.url
              : null,
          externalUri: uri,
        ),
      ];
    }
    // Fallback: search YouTube for the track by name + first artist
    final searchQuery = StringBuffer(track.name);
    if (track.artists.isNotEmpty) {
      searchQuery.write(' ${track.artists.first.name}');
    }
    AppLogger.log.i(
      '[_NativeAudioSource.matches] No externalUri — searching YouTube for: "${searchQuery}"',
    );
    try {
      final videos = await EngineFailover.tryEngines(
        engines: allEngines,
        operation: (engine) async {
          final results = await engine.searchVideos(searchQuery.toString());
          return results.take(5).toList();
        },
      );
      AppLogger.log.i(
        '[_NativeAudioSource.matches] YouTube search returned ${videos.length} results',
      );
      if (videos.isEmpty) {
        AppLogger.log.w(
          '[_NativeAudioSource.matches] No YouTube results for "${searchQuery}"',
        );
        return const [];
      }
      return videos.map((video) {
        return DeeMusiqAudioSourceMatchObject(
          id: video.id.value,
          title: video.title,
          artists: [video.author],
          duration: video.duration ?? Duration.zero,
          thumbnail: video.thumbnails.highResUrl.isNotEmpty
              ? video.thumbnails.highResUrl
              : null,
          externalUri: "$_ytPrefix${video.id.value}",
        );
      }).toList();
    } catch (e, stack) {
      AppLogger.log.w(
        'YouTube fallback search failed for "${track.name}": ${e.toString()}',
      );
      AppLogger.reportError(e, stack);
      return const [];
    }
  }

  @override
  Future<List<DeeMusiqAudioSourceStreamObject>> streams(
      DeeMusiqAudioSourceMatchObject match) async {
    final uri = match.externalUri;
    if (uri.startsWith(_ytPrefix)) {
      final videoId = uri.substring(_ytPrefix.length);
      try {
        AppLogger.log.i('Fetching YouTube streams for videoId=$videoId using engine failover...');
        final manifest = await EngineFailover.tryEngines(
          engines: allEngines,
          operation: (engine) => engine.getStreamManifest(videoId),
        );
        AppLogger.log.i(
          'Got manifest for $videoId: ${manifest.audioOnly.length} audio streams before filtering',
        );
        final filteredStreams = YouTubeAudioQualityService.filterStreams(
          manifest.audioOnly,
        );
        if (filteredStreams.isEmpty) {
          AppLogger.log.w(
            'All ${manifest.audioOnly.length} streams for $videoId were filtered out by quality settings',
          );
        }
        AppLogger.log.i(
          'Returning ${filteredStreams.length} streams for $videoId after quality filtering',
        );
        return filteredStreams
            .map(
              (s) => DeeMusiqAudioSourceStreamObject(
                url: s.url.toString(),
                container: s.container.name,
                type: DeeMusiqMediaCompressionType.lossy,
                bitrate: s.bitrate.bitsPerSecond.toDouble(),
              ),
            )
            .toList();
      } catch (e, stack) {
        if (e is EngineFailoverException) {
          AppLogger.log.w(
            'Engine failover exhausted for $videoId: ${e.message} — Errors: ${e.errors.join(" | ")}',
          );
        } else {
          AppLogger.log.w('Failed to get YouTube streams for $videoId: ${e.toString()}');
        }
        AppLogger.reportError(e, stack);
        return const [];
      }
    }
    if (uri.startsWith(_urlPrefix)) {
      final url = uri.substring(_urlPrefix.length);
      return [
        DeeMusiqAudioSourceStreamObject(
          url: url,
          container: url.split(".").last.split("?").first,
          type: DeeMusiqMediaCompressionType.lossy,
        ),
      ];
    }
    return const [];
  }
}

/// Wires the native endpoints onto a [MetadataPlugin]-shaped object. Used by the
/// `MetadataPlugin.native` constructor.
class DeeMusiqNativeEndpoints {
  final _CatalogApi _api = _CatalogApi();
  late final MetadataAuthEndpoint auth = _NativeAuth();
  late final MetadataPluginAudioSourceEndpoint audioSource;
  late final MetadataPluginAlbumEndpoint album;
  late final MetadataPluginArtistEndpoint artist = _NativeArtist(_api);
  late final MetadataPluginBrowseEndpoint browse;
  late final MetadataPluginSearchEndpoint search;
  late final MetadataPluginPlaylistEndpoint playlist = _NativePlaylist(_api);
  late final MetadataPluginTrackEndpoint track = _NativeTrack(_api);
  late final MetadataPluginUserEndpoint user = _NativeUser();
  late final MetadataPluginCore core = _NativeCore();

  DeeMusiqNativeEndpoints(YouTubeEngine youtubeEngine, List<YouTubeEngine> allEngines) {
    audioSource = _NativeAudioSource(youtubeEngine, allEngines);
    search = _NativeSearch(_api, youtubeEngine, allEngines);
    browse = _NativeBrowse(_api, allEngines);
    album = _NativeAlbum(_api, allEngines);
  }
}
