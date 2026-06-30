import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginTrackEndpoint {
  MetadataPluginTrackEndpoint();

  Future<DeeMusiqFullTrackObject> getTrack(String id) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> save(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<void> unsave(List<String> ids) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<DeeMusiqFullTrackObject>> radio(String id) async {
    throw UnimplementedError('Native plugin must override');
  }
}
