import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureFlags {
  const FeatureFlags({
    required this.useMockAiStoryService,
    required this.useMockRepositories,
    required this.enableAds,
    required this.enablePaywall,
  });

  final bool useMockAiStoryService;
  final bool useMockRepositories;
  final bool enableAds;
  final bool enablePaywall;
}

/// MVP varsayılanları: AI/ads/paywall stub ile başlar.
final featureFlagsProvider = Provider<FeatureFlags>(
  (ref) => const FeatureFlags(
    useMockAiStoryService: true,
    useMockRepositories: false,
    enableAds: true,
    enablePaywall: true,
  ),
);
