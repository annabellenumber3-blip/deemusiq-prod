import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginAlbumEndpoint {
  MetadataPluginAlbumEndpoint();

  Future<DeeMusiqFullAlbumObject> getAlbum(String id) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqFullTrackObject>> tracks(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<DeeMusiqSimpleAlbumObject>> releases({
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
}
