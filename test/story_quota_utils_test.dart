import 'package:flutter_test/flutter_test.dart';

import 'package:masal_evi/core/services/quota/story_quota_utils.dart';

void main() {
  test('computeNextResetDate bir sonraki ayın 1. günü', () {
    final from = DateTime(2026, 3, 15, 12, 30);
    final next = computeNextResetDate(from);
    expect(next, DateTime(2026, 4, 1, 0, 0, 0, 0));
  });

  test('shouldReset yalnızca resetDate\'den sonra resetler', () {
    final resetDate = DateTime(2026, 4, 1, 0, 0);
    expect(shouldReset(DateTime(2026, 4, 1, 0, 0), resetDate), isFalse);
    expect(shouldReset(DateTime(2026, 4, 1, 0, 1), resetDate), isTrue);
  });

  test('canGenerateStory free limit aşımında engeller', () {
    const limit = 5;
    expect(
      canGenerateStory(
        storyCount: 4,
        isPremium: false,
        isAdmin: false,
        freeStoriesPerMonth: limit,
      ),
      isTrue,
    );
    expect(
      canGenerateStory(
        storyCount: 5,
        isPremium: false,
        isAdmin: false,
        freeStoriesPerMonth: limit,
      ),
      isFalse,
    );
  });

  test('canGenerateStory premium/admin limit bypass', () {
    expect(
      canGenerateStory(
        storyCount: 999,
        isPremium: true,
        isAdmin: false,
        freeStoriesPerMonth: 5,
      ),
      isTrue,
    );
    expect(
      canGenerateStory(
        storyCount: 999,
        isPremium: false,
        isAdmin: true,
        freeStoriesPerMonth: 5,
      ),
      isTrue,
    );
  });
}

