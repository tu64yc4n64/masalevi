import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_story_service.dart';
import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/services/stories/story_repository.dart';
import '../../../core/services/stories/stories_repository_api.dart';
import '../../../features/children/application/child_profile_controller.dart';
import '../../../core/services/quota/story_quota_controller.dart';

class StoryCreateState {
  const StoryCreateState({required this.isGenerating, this.lastStoryId});
  final bool isGenerating;
  final String? lastStoryId;

  StoryCreateState copyWith({bool? isGenerating, String? lastStoryId}) {
    return StoryCreateState(
      isGenerating: isGenerating ?? this.isGenerating,
      lastStoryId: lastStoryId ?? this.lastStoryId,
    );
  }
}

class StoryCreateController extends Notifier<StoryCreateState> {
  @override
  StoryCreateState build() => const StoryCreateState(isGenerating: false);

  Future<String> generateAndCreateStory({
    required String theme,
    required String value,
    required StoryLength length,
  }) async {
    final child = ref.read(childProfileProvider);
    if (child == null) {
      throw StateError('Child profile is missing');
    }

    await ref
        .read(storyQuotaControllerProvider.notifier)
        .consumeStoryQuotaOrThrow();
    state = state.copyWith(isGenerating: true, lastStoryId: null);
    try {
      final service = ref.read(aiStoryServiceProvider);
      final req = AiStoryRequest(
        childId: child.childId,
        childName: child.name,
        age: child.age,
        gender: child.gender,
        theme: theme,
        value: value,
        length: length,
      );
      final sanitizedReq = sanitizeAiRequest(req);

      final result = await service.generateStory(sanitizedReq);
      if (result.storyId != null && result.storyId!.isNotEmpty) {
        state = state.copyWith(
          isGenerating: false,
          lastStoryId: result.storyId,
        );
        return result.storyId!;
      }

      final repo = ref.read(storiesRepositoryApiProvider);
      final userId = ref.read(userIdProvider);
      final story = await repo.createStory(
        userId: userId,
        childId: child.childId,
        title: result.title,
        content: result.content,
      );
      await ref
          .read(usersRepositoryApiProvider)
          .incrementStoryCount(uid: userId);
      state = state.copyWith(isGenerating: false, lastStoryId: story.storyId);
      return story.storyId;
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }
}

final storyCreateControllerProvider =
    NotifierProvider<StoryCreateController, StoryCreateState>(
      StoryCreateController.new,
    );
