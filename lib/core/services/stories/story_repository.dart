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
    this.audioUrl,
    this.isFavorite = false,
  });

  final String storyId;
  final String userId;
  final String childId;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? audioUrl;
  final bool isFavorite;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'childId': childId,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'audioUrl': audioUrl,
      'isFavorite': isFavorite,
    };
  }

  static StoryEntity fromMap({
    required String storyId,
    required Map<String, dynamic> map,
  }) {
    return StoryEntity(
      storyId: (map['id'] as String?) ?? storyId,
      userId: (map['userId'] as String?) ?? (map['user_id'] as String?) ?? '',
      childId:
          (map['childId'] as String?) ?? (map['child_id'] as String?) ?? '',
      title: (map['title'] as String?) ?? 'Masal',
      content: (map['content'] as String?) ?? '',
      createdAt: _parseStoryDateTime(map['createdAt'] ?? map['created_at']),
      audioUrl: (map['audioUrl'] as String?) ?? (map['audio_url'] as String?),
      isFavorite:
          (map['isFavorite'] as bool?) ??
          (map['is_favorite'] as bool?) ??
          false,
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
      audioUrl: audioUrl,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

DateTime _parseStoryDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }
  return DateTime.now();
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
      audioUrl: null,
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
