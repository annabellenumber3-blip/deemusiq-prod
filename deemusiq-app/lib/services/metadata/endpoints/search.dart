import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginSearchEndpoint {
  MetadataPluginSearchEndpoint();

  List<String> get chips {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqSearchResponseObject> all(String query) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> albums(
    String query, {
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>> artists(
    String query, {
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimplePlaylistObject>>
      playlists(
    String query, {
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
    String query, {
    int? limit,
    int? offset,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }
}
