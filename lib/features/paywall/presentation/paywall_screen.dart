import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/theme/widgets/masal_primary_button.dart';
import '../application/paywall_controller.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paywallControllerProvider);
    return MasalPage(
      title: 'Premium',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            state.isTrialActive
                ? 'Deneme suresi bitmeden premium planlarini inceleyebilirsin.'
                : 'Reklamsiz deneyim ve daha genis aylik masal hakki burada acilacak.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 22),
          GlassCard(
            borderRadius: 18,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Text(
                    'Aylık: \$2.99',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Yıllık: \$19.99',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Su anki plan hakki: ayda ${state.monthlyQuota >= 1000000 ? 'sinirsiz' : state.monthlyQuota} masal',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            child: MasalPrimaryButton(
              height: 56,
              borderRadius: 16,
              label: "Premium’a Geç (Mock)",
              onPressed: () {
                if (!state.isPremium) {
                  ref
                      .read(paywallControllerProvider.notifier)
                      .purchasePremiumMock();
                }
                context.go('/home');
              },
            ),
          ),
        ],
      ),
    );
  }
}
