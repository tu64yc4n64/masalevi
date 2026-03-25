import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/stories/story_repository.dart';
import '../../../core/services/stories/stories_repository_api.dart';

class LibraryState {
  const LibraryState({required this.stories});
  final List<StoryEntity> stories;
}

class LibraryController extends Notifier<LibraryState> {
  @override
  LibraryState build() {
    final stories = ref.watch(storiesListProvider);
    // MVP: Kütüphane = sadece beğenilen masallar
    final favorites = stories.where((s) => s.isFavorite).toList(growable: false);
    return LibraryState(stories: favorites);
  }

  void toggleFavorite({required String storyId, required bool nextValue}) {
    ref.read(storiesRepositoryApiProvider).toggleFavorite(
          storyId: storyId,
          nextValue: nextValue,
        );
  }
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryState>(LibraryController.new);

