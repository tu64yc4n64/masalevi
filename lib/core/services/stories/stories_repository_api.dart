import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
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
    return _ref.read(storyRepositoryProvider.notifier).createStory(
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
    _ref.read(storyRepositoryProvider.notifier).toggleFavorite(
          storyId: storyId,
          isFavorite: nextValue,
        );
  }
}

/// Firebase tarafına geçişte bu implementasyon genişletilecek.
class FirestoreStoriesRepositoryApi implements StoriesRepositoryApi {
  FirestoreStoriesRepositoryApi(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _stories =>
      _firestore.collection('stories');

  @override
  Future<StoryEntity> createStory({
    required String userId,
    required String childId,
    required String title,
    required String content,
  }) async {
    final doc = _stories.doc();
    final story = StoryEntity(
      storyId: doc.id,
      userId: userId,
      childId: childId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      isFavorite: false,
    );
    await doc.set(story.toMap());
    return story;
  }

  @override
  Future<void> toggleFavorite({
    required String storyId,
    required bool nextValue,
  }) async {
    await _stories.doc(storyId).update({'isFavorite': nextValue});
  }
}

final _firestoreStoriesProvider = StreamProvider<List<StoryEntity>>((ref) {
  final userId = ref.watch(userIdProvider);
  if (userId == 'mock_user') {
    return Stream<List<StoryEntity>>.value(const []);
  }

  return FirebaseFirestore.instance
      .collection('stories')
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
    final stories = snapshot.docs
        .map((doc) => StoryEntity.fromMap(storyId: doc.id, map: doc.data()))
        .toList(growable: false);
    stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stories;
  });
});

final storiesListProvider = Provider<List<StoryEntity>>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  if (flags.useMockRepositories) {
    return ref.watch(storyRepositoryProvider);
  }
  return ref.watch(_firestoreStoriesProvider).value ?? const [];
});

final storiesRepositoryApiProvider = Provider<StoriesRepositoryApi>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  if (flags.useMockRepositories) {
    return MockStoriesRepositoryApi(ref);
  }
  return FirestoreStoriesRepositoryApi(FirebaseFirestore.instance);
});
