import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginUserEndpoint {
  MetadataPluginUserEndpoint();

  Future<DeeMusiqUserObject> me() async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> savedTracks({
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimplePlaylistObject>>
      savedPlaylists({
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>>
      savedAlbums({
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>>
      savedArtists({
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<bool> isSavedPlaylist(String playlistId) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<bool>> isSavedTracks(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<bool>> isSavedAlbums(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<bool>> isSavedArtists(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }
}
