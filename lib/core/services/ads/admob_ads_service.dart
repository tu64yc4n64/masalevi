import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import 'ads_service.dart';

/// COPPA uyumu için AdMob tag/parametreleri (MVP stub).
///
/// Gerçek entegrasyonda Google Mobile Ads SDK ile `childDirectedTreatment`,
/// `underAgeOfConsent`, `maxAdContentRating` değerleri kullanılmalı.
class AdMobAdsService implements AdsService {
  AdMobAdsService({required this.enableAds});

  final bool enableAds;

  static const String maxAdContentRating = 'G';

  @override
  Widget buildBanner() {
    if (!enableAds) return const SizedBox.shrink();
    return Container(
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white12,
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Reklam (Stub)',
        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
      ),
    );
  }
}

final adMobAdsServiceProvider = Provider<AdsService>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  return AdMobAdsService(enableAds: flags.enableAds);
});

