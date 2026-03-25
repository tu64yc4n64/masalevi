import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admob_ads_service.dart';
import '../../config/feature_flags.dart';
import '../purchases/purchases_service.dart';

abstract class AdsService {
  /// MVP stub: Banner’ı yükleyip gösterir.
  /// Story player ekranında çağrılmamalı.
  Widget buildBanner();
}

/// Varsayılan MVP: reklam kapalı.
class StubAdsService implements AdsService {
  @override
  Widget buildBanner() {
    return const SizedBox.shrink();
  }
}

final adsServiceProvider = Provider<AdsService>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final enableAds = flags.enableAds && ref.watch(shouldShowAdsProvider);
  if (!enableAds) return StubAdsService();
  return AdMobAdsService(enableAds: enableAds);
});
