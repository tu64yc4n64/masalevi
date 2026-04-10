import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/stories/story_repository.dart';
import '../../../core/services/stories/stories_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/theme/widgets/favorite_heart_button.dart';
import '../../children/application/child_profile_controller.dart';
import '../application/story_player_controller.dart';
import 'story_voice_picker_sheet.dart';

class StoryPlayerScreen extends ConsumerStatefulWidget {
  const StoryPlayerScreen({
    super.key,
    required this.storyId,
    this.initialVoiceId,
    this.autoPlay = false,
    this.forceVoicePicker = false,
  });

  final String storyId;
  final String? initialVoiceId;
  final bool autoPlay;
  final bool forceVoicePicker;

  @override
  ConsumerState<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends ConsumerState<StoryPlayerScreen> {
  bool _didAutoplay = false;
  bool _didPromptForVoice = false;
  String? _overrideVoiceId;

  Future<void> _playStoryAudio(
    StoryEntity story, {
    required String selectedVoiceId,
  }) async {
    try {
      await ref
          .read(storyPlayerControllerProvider.notifier)
          .play(
            text: story.content,
            wordCount: story.content
                .split(RegExp(r'\s+'))
                .where((w) => w.isNotEmpty)
                .length,
            audioUrl: '/stories/${story.storyId}/audio',
            selectedVoiceId: selectedVoiceId,
          );
    } catch (error) {
      if (!mounted) return;
      final raw = error.toString().replaceFirst('Bad state: ', '');
      final message = raw.contains('Masal sesi alinamadi: 401')
          ? 'Secilen ses su an uretilemedi. ElevenLabs kredisi bitmis olabilir.'
          : 'Masal sesi su an acilamadi. $raw';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    _overrideVoiceId = widget.initialVoiceId;
  }

  Future<void> _changeVoiceAndMaybePlay(StoryEntity story) async {
    final selectedVoiceId = await showStoryVoicePickerSheet(
      context,
      ref,
      initialVoiceId:
          _overrideVoiceId ??
          story.selectedVoiceId ??
          ref.read(childProfileProvider)?.selectedVoiceId,
      title: 'Bu masal icin ses sec',
    );
    if (selectedVoiceId == null || selectedVoiceId.isEmpty) return;

    await ref
        .read(storiesRepositoryApiProvider)
        .setStoryVoice(storyId: story.storyId, voiceId: selectedVoiceId);
    if (!mounted) return;
    setState(() {
      _overrideVoiceId = selectedVoiceId;
      _didAutoplay = true;
    });
    await _playStoryAudio(story, selectedVoiceId: selectedVoiceId);
  }

  Future<void> _ensureVoiceSelectionAndAutoplay(
    StoryEntity story, {
    bool forcePrompt = false,
  }) async {
    if (_didPromptForVoice) return;
    _didPromptForVoice = true;
    if (!forcePrompt) {
      final existingVoiceId = _overrideVoiceId ?? story.selectedVoiceId;
      if (existingVoiceId != null && existingVoiceId.isNotEmpty) {
        setState(() {
          _didAutoplay = true;
        });
        await _playStoryAudio(story, selectedVoiceId: existingVoiceId);
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final selectedVoiceId = await showStoryVoicePickerSheet(
      context,
      ref,
      initialVoiceId:
          _overrideVoiceId ??
          story.selectedVoiceId ??
          ref.read(childProfileProvider)?.selectedVoiceId,
      title: 'Bu masal icin ses sec',
    );
    if (!mounted || selectedVoiceId == null || selectedVoiceId.isEmpty) return;

    await ref
        .read(storiesRepositoryApiProvider)
        .setStoryVoice(storyId: story.storyId, voiceId: selectedVoiceId);
    if (!mounted) return;
    setState(() {
      _overrideVoiceId = selectedVoiceId;
      _didAutoplay = true;
    });
    await _playStoryAudio(story, selectedVoiceId: selectedVoiceId);
  }

  Future<void> _confirmDeleteStory(
    BuildContext context,
    WidgetRef ref,
    StoryEntity story,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Masali sil'),
        content: Text('"${story.title}" masalini silmek istiyor musun?'),
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
        .read(storiesRepositoryApiProvider)
        .deleteStory(storyId: story.storyId);
    if (!context.mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesListProvider);
    final backendStoryAsync = ref.watch(
      backendStoryByIdProvider(widget.storyId),
    );
    StoryEntity? story = backendStoryAsync.value;
    if (story == null) {
      try {
        story = stories.firstWhere((s) => s.storyId == widget.storyId);
      } catch (_) {
        story = null;
      }
    }
    final playerState = ref.watch(storyPlayerControllerProvider);
    if (story == null && backendStoryAsync.isLoading) {
      return const MasalPage(child: Center(child: CircularProgressIndicator()));
    }
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
    final storyVoiceId = _overrideVoiceId ?? resolvedStory.selectedVoiceId;
    final activeVoiceId =
        storyVoiceId ??
        ref.watch(childProfileProvider)?.selectedVoiceId ??
        'Burcu';

    final words = resolvedStory.content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (widget.autoPlay && !_didAutoplay && !playerState.isPlaying) {
      final shouldPromptForVoice =
          widget.forceVoicePicker ||
          storyVoiceId == null ||
          storyVoiceId.isEmpty;
      if (shouldPromptForVoice) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureVoiceSelectionAndAutoplay(
            resolvedStory,
            forcePrompt: widget.forceVoicePicker,
          );
        });
      } else {
        _didAutoplay = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _playStoryAudio(resolvedStory, selectedVoiceId: activeVoiceId);
        });
      }
    }

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
                      ref
                          .read(storiesRepositoryApiProvider)
                          .toggleFavorite(
                            storyId: resolvedStory.storyId,
                            nextValue: !resolvedStory.isFavorite,
                          );
                    },
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: 'Sesi degistir',
                      icon: const Icon(Icons.record_voice_over_outlined),
                      onPressed: () => _changeVoiceAndMaybePlay(resolvedStory),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: 'Sil',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          _confirmDeleteStory(context, ref, resolvedStory),
                    ),
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
                            color:
                                i == playerState.activeWordIndex &&
                                    playerState.isPlaying
                                ? AppColors.primaryPurple.withValues(
                                    alpha: 0.22,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            words[i],
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color:
                                      i == playerState.activeWordIndex &&
                                          playerState.isPlaying
                                      ? AppColors.accentOrange
                                      : AppColors.textBase,
                                  fontWeight:
                                      i == playerState.activeWordIndex &&
                                          playerState.isPlaying
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
                      onPressed: () async {
                        final controller = ref.read(
                          storyPlayerControllerProvider.notifier,
                        );
                        if (playerState.isPlaying) {
                          controller.pause();
                        } else {
                          if (storyVoiceId == null || storyVoiceId.isEmpty) {
                            await _ensureVoiceSelectionAndAutoplay(
                              resolvedStory,
                            );
                            return;
                          }
                          await _playStoryAudio(
                            resolvedStory,
                            selectedVoiceId: activeVoiceId,
                          );
                        }
                      },
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(
                        playerState.isPlaying
                            ? 'Okumayı Durdur'
                            : 'Okumaya Başla',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPurple,
                        foregroundColor: AppColors.textBase,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
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
