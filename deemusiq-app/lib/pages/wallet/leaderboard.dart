import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter_extension.dart';
import 'package:deemusiq/collections/deemusiq_icons.dart';
import 'package:deemusiq/components/image/universal_image.dart';
import 'package:deemusiq/components/titlebar/titlebar.dart';
import 'package:deemusiq/components/wallet/push_song_dialog.dart';
import 'package:deemusiq/components/wallet/wallet_common.dart';
import 'package:deemusiq/models/wallet/pushed_song.dart';
import 'package:deemusiq/provider/wallet/leaderboard_provider.dart';
import 'package:deemusiq/provider/wallet/wallet_provider.dart';
import 'package:deemusiq/services/wallet/wallet_api.dart';

@RoutePage()
class PushLeaderboardPage extends HookConsumerWidget {
  static const name = "push-leaderboard";

  const PushLeaderboardPage({super.key});

  /// Adapts a global entry to the tile's [PushedSong] shape (lastPushedAt is
  /// not shown on the board, so a zero epoch placeholder is fine).
  static PushedSong _toSong(LeaderboardEntry e) => PushedSong(
        id: e.songId,
        title: e.title,
        artist: e.artist,
        artistId: e.artistId,
        imageUrl: e.imageUrl,
        totalTokens: e.totalTokens,
        pushCount: e.pushCount,
        lastPushedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  Widget _emptyCard() {
    return Card(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(DeeMusiqIcons.boost, size: 32, color: deeMusiqOrange),
          const Gap(10),
          const Text("Nothing trending yet").semiBold(),
          const Gap(4),
          const Text(
            "Push a song from its menu or the player to start the board.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = WalletApiClient.instance.isConfigured;

    return SafeArea(
      bottom: false,
      child: Scaffold(
        headers: [
          TitleBar(title: const Text("Trending pushes")),
        ],
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      filled: true,
                      fillColor: context.theme.colorScheme.muted,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(DeeMusiqIcons.trophy,
                              color: deeMusiqOrange),
                          const Gap(10),
                          const Expanded(
                            child: Text(
                              "The most-pushed songs rise to the top. Push your "
                              "favourites to move them up the board.",
                            ),
                          ),
                          if (online)
                            Button.ghost(
                              leading:
                                  const Icon(DeeMusiqIcons.refresh, size: 16),
                              onPressed: () =>
                                  ref.invalidate(leaderboardProvider),
                              child: const Text("Refresh"),
                            ),
                        ],
                      ),
                    ),
                    const Gap(16),
                    if (online)
                      _globalBoard(ref)
                    else
                      _localBoard(ref),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The global cross-user board from the backend, with loading/error states.
  Widget _globalBoard(WidgetRef ref) {
    final board = ref.watch(leaderboardProvider);
    return board.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Card(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(DeeMusiqIcons.info, size: 28, color: deeMusiqOrange),
            const Gap(10),
            const Text("Couldn't load the board").semiBold(),
            const Gap(4),
            Text(
              error is WalletApiException ? error.message : error.toString(),
              textAlign: TextAlign.center,
            ).muted().small(),
            const Gap(12),
            Button.outline(
              onPressed: () => ref.invalidate(leaderboardProvider),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
      data: (entries) => entries.isEmpty
          ? _emptyCard()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LeaderTile(
                      rank: entry.rank,
                      song: _toSong(entry),
                    ),
                  ),
              ],
            ),
    );
  }

  /// Offline fallback: this device's own pushes, clearly labelled.
  Widget _localBoard(WidgetRef ref) {
    final pushed = ref.watch(walletProvider.select((s) => s.pushedSongs));
    final ranked = [...pushed]
      ..sort((a, b) => b.totalTokens.compareTo(a.totalTokens));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Your pushes (offline)").muted().xSmall(),
        const Gap(8),
        if (ranked.isEmpty)
          _emptyCard()
        else
          for (final entry in ranked.asMap().entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LeaderTile(
                rank: entry.key + 1,
                song: entry.value,
              ),
            ),
      ],
    );
  }
}

class _LeaderTile extends ConsumerWidget {
  final int rank;
  final PushedSong song;

  const _LeaderTile({required this.rank, required this.song});

  Color _rankColor() {
    switch (rank) {
      case 1:
        return const Color(0xFFFFC107);
      case 2:
        return const Color(0xFFB0BEC5);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return deeMusiqOrange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      borderColor: rank <= 3 ? _rankColor() : null,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              "#$rank",
              style: TextStyle(
                color: _rankColor(),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.imageUrl != null
                ? UniversalImage(
                    path: song.imageUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: deeMusiqOrange.withValues(alpha: 0.15),
                    child: const Icon(DeeMusiqIcons.music,
                        color: deeMusiqOrange),
                  ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(song.title, maxLines: 1).semiBold(),
                Text(
                  "${song.artist} · ${song.pushCount} push${song.pushCount == 1 ? "" : "es"}",
                  maxLines: 1,
                ).muted().xSmall(),
              ],
            ),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(DeeMusiqIcons.token,
                      size: 14, color: deeMusiqOrange),
                  const Gap(4),
                  Text(
                    formatTokens(song.totalTokens),
                    style: const TextStyle(
                      color: deeMusiqOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Button.ghost(
                leading: const Icon(DeeMusiqIcons.boost, size: 14),
                onPressed: () => showPushSongDialog(
                  context,
                  songId: song.id,
                  title: song.title,
                  artist: song.artist,
                  artistId: song.artistId,
                  imageUrl: song.imageUrl,
                ),
                child: const Text("Push"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
