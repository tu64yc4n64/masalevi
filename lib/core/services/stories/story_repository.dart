import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/auth/firebase_auth_service.dart';

class StoryEntity {
  StoryEntity({
    required this.storyId,
    required this.userId,
    required this.childId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isFavorite = false,
  });

  final String storyId;
  final String userId;
  final String childId;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isFavorite;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'childId': childId,
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
    };
  }

  static StoryEntity fromMap({
    required String storyId,
    required Map<String, dynamic> map,
  }) {
    return StoryEntity(
      storyId: storyId,
      userId: (map['userId'] as String?) ?? '',
      childId: (map['childId'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Masal',
      content: (map['content'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isFavorite: (map['isFavorite'] as bool?) ?? false,
    );
  }

  StoryEntity copyWith({bool? isFavorite}) {
    return StoryEntity(
      storyId: storyId,
      userId: userId,
      childId: childId,
      title: title,
      content: content,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class StoryRepository extends Notifier<List<StoryEntity>> {
  @override
  List<StoryEntity> build() => const [];

  Future<StoryEntity> createStory({
    required String userId,
    required String childId,
    required String title,
    required String content,
  }) async {
    final story = StoryEntity(
      storyId: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      childId: childId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
      isFavorite: false,
    );
    state = [story, ...state];
    return story;
  }

  void toggleFavorite({required String storyId, required bool isFavorite}) {
    state = [
      for (final s in state)
        if (s.storyId == storyId) s.copyWith(isFavorite: isFavorite) else s,
    ];
  }
}

final storyRepositoryProvider =
    NotifierProvider<StoryRepository, List<StoryEntity>>(StoryRepository.new);

final userIdProvider = Provider<String>((ref) {
  return ref.watch(currentFirebaseUserProvider)?.uid ?? 'mock_user';
});

final storyByIdProvider = Provider.family<StoryEntity?, String>((ref, id) {
  final stories = ref.watch(storyRepositoryProvider);
  try {
    return stories.firstWhere((s) => s.storyId == id);
  } catch (_) {
    return null;
  }
});
