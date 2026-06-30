import 'package:deemusiq/models/metadata/metadata.dart';

class MetadataPluginAudioSourceEndpoint {
  MetadataPluginAudioSourceEndpoint();

  List<DeeMusiqAudioSourceContainerPreset> get supportedPresets {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<DeeMusiqAudioSourceMatchObject>> matches(
    DeeMusiqFullTrackObject track,
  ) async {
    throw UnimplementedError('Native plugin must override');
  }

  Future<List<DeeMusiqAudioSourceStreamObject>> streams(
    DeeMusiqAudioSourceMatchObject match,
  ) async {
    throw UnimplementedError('Native plugin must override');
  }
}
