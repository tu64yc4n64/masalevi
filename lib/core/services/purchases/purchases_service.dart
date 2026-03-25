import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/users_repository_api.dart';

class PurchasesService {
  const PurchasesService();

  static const int freeStoriesPerMonth = 20;
  static const int trialStoriesPerMonth = 50;
  static const int premiumStoriesPerMonth = 200;
}

final purchasesServiceProvider = Provider<PurchasesService>(
  (ref) => const PurchasesService(),
);

final isTrialActiveProvider = Provider<bool>((ref) {
  return ref.watch(currentAppUserProvider)?.isTrialActive ?? false;
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(currentAppUserProvider)?.isPremium ?? false;
});

final hasUnlimitedAccessProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  if (user == null) return false;
  return user.isAdminLike;
});

final canAccessPremiumFeaturesProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  if (user == null) return false;
  return user.isPremium || user.isAdminLike || user.isTrialActive;
});

final monthlyStoryQuotaProvider = Provider<int>((ref) {
  final user = ref.watch(currentAppUserProvider);
  if (user == null) return PurchasesService.freeStoriesPerMonth;
  if (user.isAdminLike) return 1 << 30;
  if (user.isPremium) return PurchasesService.premiumStoriesPerMonth;
  if (user.isTrialActive) return PurchasesService.trialStoriesPerMonth;
  return PurchasesService.freeStoriesPerMonth;
});

final shouldShowAdsProvider = Provider<bool>((ref) {
  final user = ref.watch(currentAppUserProvider);
  if (user == null) return false;
  return !user.isPremium && !user.isAdminLike && !user.isTrialActive;
});
