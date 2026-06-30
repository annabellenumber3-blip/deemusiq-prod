import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginArtistEndpoint {
  MetadataPluginArtistEndpoint();

  Future<DeeMusiqFullArtistObject> getArtist(String id) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> topTracks(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> albums(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> save(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> unsave(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullArtistObject>> related(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }
}
