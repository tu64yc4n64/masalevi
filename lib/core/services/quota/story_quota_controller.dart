import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/users_repository_api.dart';
import '../purchases/purchases_service.dart';
import '../user/user_role_service.dart';
import 'story_quota_utils.dart';

class StoryQuotaState {
  const StoryQuotaState({
    required this.storyCount,
    required this.resetDate,
    required this.isPremium,
    required this.isAdmin,
    required this.isTrialActive,
    required this.monthlyQuota,
  });

  final int storyCount;
  final DateTime resetDate;
  final bool isPremium;
  final bool isAdmin;
  final bool isTrialActive;
  final int monthlyQuota;

  StoryQuotaState copyWith({
    int? storyCount,
    DateTime? resetDate,
    bool? isPremium,
    bool? isAdmin,
    bool? isTrialActive,
    int? monthlyQuota,
  }) {
    return StoryQuotaState(
      storyCount: storyCount ?? this.storyCount,
      resetDate: resetDate ?? this.resetDate,
      isPremium: isPremium ?? this.isPremium,
      isAdmin: isAdmin ?? this.isAdmin,
      isTrialActive: isTrialActive ?? this.isTrialActive,
      monthlyQuota: monthlyQuota ?? this.monthlyQuota,
    );
  }
}

class StoryQuotaController extends Notifier<StoryQuotaState> {
  @override
  StoryQuotaState build() {
    final user = ref.watch(currentAppUserProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    return StoryQuotaState(
      storyCount: user?.storyCount ?? 0,
      resetDate: user?.storyResetDate ?? computeNextResetDate(DateTime.now()),
      isPremium: isPremium,
      isAdmin: isAdmin,
      isTrialActive: isTrialActive,
      monthlyQuota: monthlyQuota,
    );
  }

  Future<void> consumeStoryQuotaOrThrow() async {
    final now = DateTime.now();
    var current = state;
    if (shouldReset(now, current.resetDate)) {
      current = current.copyWith(
        storyCount: 0,
        resetDate: computeNextResetDate(now),
      );
    }

    if (current.isAdmin) {
      // Admin/owner için limit yok.
      state = current;
      return;
    }

    if (!canGenerateStory(
      storyCount: current.storyCount,
      isPremium: current.isPremium,
      isAdmin: current.isAdmin,
      freeStoriesPerMonth: current.monthlyQuota,
    )) {
      throw StateError('FREE_MONTHLY_LIMIT_REACHED');
    }

    state = current.copyWith(storyCount: current.storyCount + 1);
  }
}

final storyQuotaControllerProvider =
    NotifierProvider<StoryQuotaController, StoryQuotaState>(
      StoryQuotaController.new,
    );
