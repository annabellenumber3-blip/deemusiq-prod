import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';
import 'package:deemusiq/services/wallet/payment_service.dart'
    show PaymentGatewayConfig;
import 'package:deemusiq/services/logger/logger.dart';

/// A single recommended track as returned from the backend.
class RecommendedTrack {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final String? coverUrl;
  final String? albumId;
  final String? albumTitle;
  final int? durationMs;
  final String sourceType;
  final String sourceRef;
  final String? externalUri;
  final List<String> reasons;

  const RecommendedTrack({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    this.coverUrl,
    this.albumId,
    this.albumTitle,
    this.durationMs,
    required this.sourceType,
    required this.sourceRef,
    this.externalUri,
    required this.reasons,
  });

  factory RecommendedTrack.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final album = json['album'] as Map<String, dynamic>?;
    final source = json['source'] as Map<String, dynamic>?;
    String externalUri = '';
    if (source != null) {
      if (source['type'] == 'youtube') {
        externalUri = 'ytsource:${source['youtubeId']}';
      } else if (source['type'] == 'url') {
        externalUri = 'urlsource:${source['url']}';
      }
    }
    final reasonsRaw = json['reasons'] as List<dynamic>?;
    return RecommendedTrack(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      artistName: artist?['name']?.toString() ?? '',
      artistId: artist?['id']?.toString() ?? '',
      coverUrl: json['coverUrl']?.toString(),
      albumId: album?['id']?.toString(),
      albumTitle: album?['title']?.toString(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      sourceType: (json['sourceType'] ?? '').toString(),
      sourceRef: (json['sourceRef'] ?? '').toString(),
      externalUri: externalUri.isNotEmpty ? externalUri : null,
      reasons: reasonsRaw?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

/// State for the recommendations notifier.
class RecommendationsState {
  final List<RecommendedTrack> tracks;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime? generatedAt;

  const RecommendationsState({
    this.tracks = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.generatedAt,
  });

  RecommendationsState copyWith({
    List<RecommendedTrack>? tracks,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? generatedAt,
  }) {
    return RecommendationsState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

class RecommendationsNotifier extends StateNotifier<RecommendationsState> {
  RecommendationsNotifier() : super(const RecommendationsState(isLoading: true));

  bool get _isConfigured => PaymentGatewayConfig.backendBaseUrl.isNotEmpty;

  Future<void> load() async {
    if (!_isConfigured) {
      state = state.copyWith(isLoading: false, error: 'backend_not_configured');
      return;
    }
    try {
      state = state.copyWith(isLoading: true, error: null);
      final data = await WalletApiClient.instance.fetchRecommendations();
      final list = (data['recommendations'] as List<dynamic>?)
              ?.map((e) =>
                  RecommendedTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final generatedAt = data['generatedAt'] != null
          ? DateTime.tryParse(data['generatedAt'] as String)
          : null;
      state = RecommendationsState(
        tracks: list,
        isLoading: false,
        generatedAt: generatedAt,
      );
    } catch (e, stack) {
      AppLogger.log.w('Failed to load recommendations: ${e.toString()}');
      AppLogger.reportError(e, stack);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    if (!_isConfigured) return;
    try {
      state = state.copyWith(isRefreshing: true, error: null);
      final data = await WalletApiClient.instance.refreshRecommendations();
      final list = (data['recommendations'] as List<dynamic>?)
              ?.map((e) =>
                  RecommendedTrack.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final generatedAt = data['generatedAt'] != null
          ? DateTime.tryParse(data['generatedAt'] as String)
          : null;
      state = RecommendationsState(
        tracks: list,
        isRefreshing: false,
        generatedAt: generatedAt,
      );
    } catch (e, stack) {
      AppLogger.log.w('Failed to refresh recommendations: ${e.toString()}');
      AppLogger.reportError(e, stack);
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }
}

final recommendationsProvider =
    StateNotifierProvider<RecommendationsNotifier, RecommendationsState>(
  (ref) => RecommendationsNotifier()..load(),
);
