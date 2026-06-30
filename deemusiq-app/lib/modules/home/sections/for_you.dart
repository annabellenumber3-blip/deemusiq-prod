import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:deemusiq/provider/recommendations/for_you.dart';

/// "For You" section on the home page showing personalised recommendations
/// based on the user's liked songs.
class HomeForYouSection extends HookConsumerWidget {
  const HomeForYouSection({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(recommendationsProvider);
    final theme = Theme.of(context);

    // Loading state
    if (state.isLoading && state.tracks.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Error state
    if (state.error != null && state.tracks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'For You',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const Spacer(),
                  Button.ghost(
                    size: ButtonSize.small,
                    onPressed: () {
                      ref.read(recommendationsProvider.notifier).refresh();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const Gap(12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 48,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const Gap(8),
                      Text(
                        'Like some songs to get personalised recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (state.tracks.isEmpty && !state.isLoading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'For You',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const Spacer(),
                  Button.ghost(
                    size: ButtonSize.small,
                    onPressed: () {
                      ref.read(recommendationsProvider.notifier).refresh();
                    },
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const Gap(12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 48,
                        color: theme.colorScheme.mutedForeground,
                      ),
                      const Gap(8),
                      Text(
                        'Like some songs to get personalised recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Refresh button
            Row(
              children: [
                Text(
                  'For You',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.foreground,
                  ),
                ),
                const Spacer(),
                if (state.isRefreshing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Button.ghost(
                    size: ButtonSize.small,
                    onPressed: () {
                      ref.read(recommendationsProvider.notifier).refresh();
                    },
                    child: const Text('Refresh'),
                  ),
              ],
            ),
            const Gap(12),
            // Horizontal scrollable track list
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.tracks.length,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (context, index) {
                  final track = state.tracks[index];
                  return _RecommendationCard(track: track);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendedTrack track;
  const _RecommendationCard({required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 180,
      child: Card(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover art / placeholder
            Container(
              width: 156,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.muted,
              ),
              child: track.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        track.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.music_note,
                          size: 40,
                          color: theme.colorScheme.mutedForeground,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.music_note,
                      size: 40,
                      color: theme.colorScheme.mutedForeground,
                    ),
            ),
            const Gap(8),
            // Title
            Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: theme.colorScheme.foreground,
              ),
            ),
            const Gap(2),
            // Artist
            Text(
              track.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
            const Gap(8),
            // Reason tags
            if (track.reasons.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: track.reasons.take(2).map((reason) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: theme.colorScheme.primary.withAlpha(30),
                    ),
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
