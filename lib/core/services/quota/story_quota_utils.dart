DateTime computeNextResetDate(DateTime from) {
  // Bir sonraki ayın 1. günü.
  return DateTime(from.year, from.month + 1, 1, 0, 0, 0, 0);
}

bool shouldReset(DateTime now, DateTime resetDate) {
  return now.isAfter(resetDate);
}

bool canGenerateStory({
  required int storyCount,
  required bool isPremium,
  required bool isAdmin,
  int freeStoriesPerMonth = 5,
}) {
  if (isPremium || isAdmin) return true;
  return storyCount < freeStoriesPerMonth;
}

