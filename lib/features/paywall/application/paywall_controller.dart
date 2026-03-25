import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/purchases/purchases_service.dart';

class PaywallState {
  const PaywallState({
    required this.isPremium,
    required this.isTrialActive,
    required this.monthlyQuota,
  });
  final bool isPremium;
  final bool isTrialActive;
  final int monthlyQuota;
}

class PaywallController extends Notifier<PaywallState> {
  @override
  PaywallState build() {
    final isPremium = ref.watch(isPremiumProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    return PaywallState(
      isPremium: isPremium,
      isTrialActive: isTrialActive,
      monthlyQuota: monthlyQuota,
    );
  }

  Future<void> purchasePremiumMock() async {
    // MVP stub: purchases hizmeti henüz premium durumunu güncellemiyor.
    // Entegrasyon geldiğinde bu method RevenueCat akışını çağıracak.
  }
}

final paywallControllerProvider =
    NotifierProvider<PaywallController, PaywallState>(PaywallController.new);
