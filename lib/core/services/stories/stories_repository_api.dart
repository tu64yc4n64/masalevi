import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import '../backend/api_client.dart';
import '../firebase/auth/firebase_auth_service.dart';
import 'story_repository.dart';

abstract class StoriesRepositoryApi {
  Future<StoryEntity> createStory({
    required String userId,
    required String childId,
    required String title,
    required String content,
  });

  Future<void> toggleFavorite({
    required String storyId,
    required bool nextValue,
  });

  Future<void> setStoryVoice({
    required String storyId,
    required String voiceId,
  });

  Future<void> deleteStory({required String storyId});
}

class MockStoriesRepositoryApi implements StoriesRepositoryApi {
  MockStoriesRepositoryApi(this._ref);

  final Ref _ref;

  @override
  Future<StoryEntity> createStory({
    required String userId,
    required String childId,
    required String title,
    required String content,
  }) {
    return _ref
        .read(storyRepositoryProvider.notifier)
        .createStory(
          userId: userId,
          childId: childId,
          title: title,
          content: content,
        );
  }

  @override
  Future<void> toggleFavorite({
    required String storyId,
    required bool nextValue,
  }) async {
    _ref
        .read(storyRepositoryProvider.notifier)
        .toggleFavorite(storyId: storyId, isFavorite: nextValue);
  }

  @override
  Future<void> deleteStory({required String storyId}) async {
    _ref.read(storyRepositoryProvider.notifier).deleteStory(storyId: storyId);
  }

  @override
  Future<void> setStoryVoice({
    required String storyId,
    required String voiceId,
  }) async {}
}

class BackendStoriesRepositoryApi implements StoriesRepositoryApi {
  BackendStoriesRepositoryApi(this._ref);

  final Ref _ref;

  ApiClient get _client => _ref.read(apiClientProvider);

  @override
  Future<StoryEntity> createStory({
    required String userId,
    required String childId,
    required String title,
    required String content,
  }) async {
    final response = await _client.postJson(
      '/stories',
      body: {'childId': childId, 'title': title, 'content': content},
    );
    final storyMap = response['story'] as Map<String, dynamic>? ?? const {};
    final story = StoryEntity.fromMap(
      storyId: storyMap['id'] as String? ?? '',
      map: storyMap,
    );
    refetchStories(_ref);
    return story;
  }

  @override
  Future<void> toggleFavorite({
    required String storyId,
    required bool nextValue,
  }) async {
    await _client.patchJson(
      '/stories/$storyId/favorite',
      body: {'isFavorite': nextValue},
    );
    refetchStories(_ref);
  }

  @override
  Future<void> deleteStory({required String storyId}) async {
    await _client.deleteJson('/stories/$storyId');
    refetchStories(_ref);
  }

  @override
  Future<void> setStoryVoice({
    required String storyId,
    required String voiceId,
  }) async {
    await _client.patchJson(
      '/stories/$storyId/voice',
      body: {'voiceId': voiceId},
    );
    refetchStories(_ref);
    _ref.invalidate(backendStoryByIdProvider(storyId));
  }
}

class StoriesRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final storiesRefreshProvider = NotifierProvider<StoriesRefreshNotifier, int>(
  StoriesRefreshNotifier.new,
);

void refetchStories(Ref ref) {
  ref.read(storiesRefreshProvider.notifier).bump();
}

final _backendStoriesProvider = StreamProvider<List<StoryEntity>>((ref) async* {
  ref.watch(storiesRefreshProvider);
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    yield const [];
    return;
  }

  final response = await ref.read(apiClientProvider).getJson('/stories');
  final stories = (response['stories'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(
        (map) =>
            StoryEntity.fromMap(storyId: map['id'] as String? ?? '', map: map),
      )
      .toList(growable: false);
  yield stories;
});

final storiesListProvider = Provider<List<StoryEntity>>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  if (flags.useMockRepositories) {
    return ref.watch(storyRepositoryProvider);
  }
  return ref.watch(_backendStoriesProvider).value ?? const [];
});

final storiesRepositoryApiProvider = Provider<StoriesRepositoryApi>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  if (flags.useMockRepositories) {
    return MockStoriesRepositoryApi(ref);
  }
  return BackendStoriesRepositoryApi(ref);
});
