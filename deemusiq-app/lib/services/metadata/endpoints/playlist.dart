import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginPlaylistEndpoint {
  MetadataPluginPlaylistEndpoint();

  Future<DeeMusiqFullPlaylistObject> getPlaylist(String id) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqFullPlaylistObject?> create(
    String userId, {
    required String name,
    String? description,
    bool? public,
    bool? collaborative,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> update(
    String playlistId, {
    String? name,
    String? description,
    bool? public,
    bool? collaborative,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> addTracks(
    String playlistId, {
    required List<String> trackIds,
    int? position,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> removeTracks(
    String playlistId, {
    required List<String> trackIds,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> save(String playlistId) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> unsave(String playlistId) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> deletePlaylist(String playlistId) async {
    throw UnimplementedError('Native plugin must override');
  }
}
