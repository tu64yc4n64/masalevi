import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/stories/story_repository.dart';
import '../../../core/services/stories/stories_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/theme/widgets/favorite_heart_button.dart';
import '../application/story_player_controller.dart';

class StoryPlayerScreen extends ConsumerWidget {
  const StoryPlayerScreen({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stories = ref.watch(storiesListProvider);
    StoryEntity? story;
    try {
      story = stories.firstWhere((s) => s.storyId == storyId);
    } catch (_) {
      story = null;
    }
    final playerState = ref.watch(storyPlayerControllerProvider);
    if (story == null) {
      return MasalPage(
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Masal bulunamadı.'),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.go('/library'),
              child: const Text('Favorilere dön'),
            ),
          ],
        ),
      );
    }
    final resolvedStory = story;

    final words =
        resolvedStory.content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/home'),
                    ),
                  ),
                  const Spacer(),
                  FavoriteHeartButton(
                    isFavorite: resolvedStory.isFavorite,
                    onToggle: () {
                      ref.read(storiesRepositoryApiProvider).toggleFavorite(
                            storyId: resolvedStory.storyId,
                            nextValue: !resolvedStory.isFavorite,
                          );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 10,
                    children: [
                      for (int i = 0; i < words.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == playerState.activeWordIndex && playerState.isPlaying
                                ? AppColors.primaryPurple.withOpacity(0.22)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            words[i],
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: i == playerState.activeWordIndex && playerState.isPlaying
                                      ? AppColors.accentOrange
                                      : AppColors.textBase,
                                  fontWeight: i == playerState.activeWordIndex && playerState.isPlaying
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final controller = ref.read(storyPlayerControllerProvider.notifier);
                        if (playerState.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play(text: resolvedStory.content, wordCount: words.length);
                        }
                      },
                      icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(playerState.isPlaying ? 'Okumayı Durdur' : 'Okumaya Başla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.textBase,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gece modu',
                        style: TextStyle(color: AppColors.textBase.withOpacity(0.7)),
                      ),
                      Text(
                        'TTS + kelime highlight (MVP stub)',
                        style: TextStyle(color: AppColors.textBase.withOpacity(0.7)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
