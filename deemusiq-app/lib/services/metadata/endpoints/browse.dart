import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginBrowseEndpoint {
  MetadataPluginBrowseEndpoint();

  Future<DeeMusiqPaginationResponseObject<DeeMusiqBrowseSectionObject<Object>>>
      sections({
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<DeeMusiqPaginationResponseObject<Object>> sectionItems(
    String id, {
    int? offset,
    int? limit,
  }) async {
    throw UnimplementedError('Native plugin must override');
  }
}
