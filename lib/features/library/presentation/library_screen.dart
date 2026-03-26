import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/favorite_heart_button.dart';
import '../../../core/theme/widgets/masal_bottom_nav.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../application/library_controller.dart';
import '../../../core/services/ads/ads_service.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _confirmDeleteStory(
    BuildContext context,
    WidgetRef ref,
    String storyId,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Masali sil'),
        content: Text('"$title" masalini silmek istiyor musun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref
        .read(libraryControllerProvider.notifier)
        .deleteStory(storyId: storyId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(libraryControllerProvider).stories;
    final adsBanner = ref.watch(adsServiceProvider).buildBanner();

    return MasalPage(
      title: 'Beğenilen Masallar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Beğenilen masallar.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textBase.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: stories.isEmpty
                ? const Center(child: Text('Henüz beğenilen masal yok.'))
                : ListView.separated(
                    itemCount: stories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = stories[i];
                      return GlassCard(
                        borderRadius: 18,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      s.content.length > 70
                                          ? '${s.content.substring(0, 70)}...'
                                          : s.content,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textBase
                                                .withOpacity(0.75),
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              FavoriteHeartButton(
                                isFavorite: s.isFavorite,
                                onToggle: () {
                                  ref
                                      .read(libraryControllerProvider.notifier)
                                      .toggleFavorite(
                                        storyId: s.storyId,
                                        nextValue: !s.isFavorite,
                                      );
                                },
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  tooltip: 'Sil',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _confirmDeleteStory(
                                    context,
                                    ref,
                                    s.storyId,
                                    s.title,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  tooltip: 'Oynat',
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () =>
                                      context.go('/story_player/${s.storyId}'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: adsBanner),
          MasalBottomNav(currentTab: ParentTab.library),
        ],
      ),
    );
  }
}
