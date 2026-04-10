import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_bottom_nav.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/theme/widgets/masal_primary_button.dart';
import '../../../core/theme/widgets/favorite_heart_button.dart';
import '../../../core/services/ads/ads_service.dart';
import '../../../core/services/firebase/models/child_model.dart';
import '../../../core/services/stories/stories_repository_api.dart';
import '../../children/application/child_profile_controller.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/services/stories/story_repository.dart';
import '../../story_player/presentation/story_voice_picker_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openStory(
    BuildContext context,
    WidgetRef ref,
    StoryEntity story,
  ) async {
    var selectedVoiceId = story.selectedVoiceId;
    if (selectedVoiceId == null || selectedVoiceId.isEmpty) {
      selectedVoiceId = await showStoryVoicePickerSheet(
        context,
        ref,
        initialVoiceId: ref.read(childProfileProvider)?.selectedVoiceId,
      );
      if (selectedVoiceId == null || selectedVoiceId.isEmpty) return;
      await ref.read(storiesRepositoryApiProvider).setStoryVoice(
            storyId: story.storyId,
            voiceId: selectedVoiceId,
          );
    }

    if (!context.mounted) return;
    context.go('/story_player/${story.storyId}?autoplay=1&voiceId=$selectedVoiceId');
  }

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
    await ref.read(storiesRepositoryApiProvider).deleteStory(storyId: storyId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProfileProvider);
    final adsBanner = ref.watch(adsServiceProvider).buildBanner();
    final stories = ref.watch(storiesListProvider);
    final activeChildId = ref.watch(activeChildIdProvider);
    final children =
        ref.watch(childrenListProvider).value ?? const <ChildModel>[];
    final filteredStories = activeChildId == null
        ? stories
        : stories
              .where((story) => story.childId == activeChildId)
              .toList(growable: false);
    final visibleStories = filteredStories.take(10).toList(growable: false);

    return MasalPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Icon(
                  Icons.nights_stay_outlined,
                  size: 92,
                  color: AppColors.accentOrange,
                ),
                Positioned(
                  left: 24,
                  top: 18,
                  child: Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.primaryPurple,
                  ),
                ),
                Positioned(
                  right: 26,
                  top: 30,
                  child: Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: AppColors.accentOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            child == null ? 'Masal Evi' : '${child.name} için masal zamanı',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          GlassCard(
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
                          child == null
                              ? 'Henuz cocuk secilmedi'
                              : 'Secili cocuk: ${child.name}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          children.isEmpty
                              ? 'Ilk profili olusturunca her cocuk icin ayri masal hazirlayacagiz.'
                              : '${children.length} cocuk profili kayitli.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textBase.withValues(
                                  alpha: 0.74,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push('/children'),
                    child: Text(children.isEmpty ? 'Cocuk ekle' : 'Degistir'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Temanı seç, değer seç, masalı oluştur.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textBase.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Oluşturulan masallar',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: visibleStories.isEmpty
                ? Center(
                    child: Text(
                      child == null
                          ? 'Masal olusturmadan once bir cocuk sec.'
                          : '${child.name} icin henuz masal yok.',
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleStories.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = visibleStories[i];
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
                                                .withValues(alpha: 0.75),
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
                                      .read(storiesRepositoryApiProvider)
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
                                  onPressed: () => _openStory(context, ref, s),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: SizedBox(
              height: 56,
              child: MasalPrimaryButton(
                height: 56,
                borderRadius: 16,
                label: 'Masal Oluştur',
                onPressed: child == null
                    ? () => context.push('/children')
                    : () => context.push('/story_create'),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.only(bottom: 8), child: adsBanner),
          MasalBottomNav(currentTab: ParentTab.home),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
