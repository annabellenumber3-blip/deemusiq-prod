import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';

/// One row of the global most-pushed leaderboard (`GET /leaderboard`).
/// Mirrors the backend's entry JSON: rank, songId, title, artist, artistId,
/// imageUrl, totalTokens, pushCount.
class LeaderboardEntry {
  final int rank;
  final String songId;
  final String title;
  final String artist;
  final String? artistId;
  final String? imageUrl;
  final int totalTokens;
  final int pushCount;

  const LeaderboardEntry({
    required this.rank,
    required this.songId,
    required this.title,
    required this.artist,
    required this.totalTokens,
    required this.pushCount,
    this.artistId,
    this.imageUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json["rank"] as num?)?.toInt() ?? 0,
      songId: json["songId"] as String? ?? "",
      title: json["title"] as String? ?? "Unknown track",
      artist: json["artist"] as String? ?? "Unknown artist",
      artistId: json["artistId"] as String?,
      imageUrl: json["imageUrl"] as String?,
      totalTokens: (json["totalTokens"] as num?)?.toInt() ?? 0,
      pushCount: (json["pushCount"] as num?)?.toInt() ?? 0,
    );
  }
}

/// Global most-pushed songs across ALL users, from the backend. Only
/// meaningful when a backend is configured — offline the leaderboard page
/// falls back to this device's own pushes.
final leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  if (!WalletApiClient.instance.isConfigured) return const [];
  final raw = await WalletApiClient.instance.fetchLeaderboard();
  return raw
      .map((e) =>
          LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
});
