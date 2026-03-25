import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/services/purchases/purchases_service.dart';
import '../../../core/services/user/user_role_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_bottom_nav.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../children/application/child_profile_controller.dart';
import '../../../core/config/feature_flags.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(childProfileProvider);
    final appUser = ref.watch(currentAppUserProvider);
    final voice = profile?.selectedVoiceId ?? 'sevgi_teyze';
    final isPremium = ref.watch(isPremiumProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final canAccessPremiumFeatures = ref.watch(
      canAccessPremiumFeaturesProvider,
    );
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final enablePaywall = ref.watch(featureFlagsProvider).enablePaywall;

    final voices = <_VoiceOption>[
      const _VoiceOption(
        id: 'sevgi_teyze',
        label: 'Sevgi Teyze',
        premium: false,
      ),
      const _VoiceOption(id: 'peri_ana', label: 'Peri Ana', premium: true),
      const _VoiceOption(id: 'dede', label: 'Dede', premium: false),
      const _VoiceOption(id: 'kahraman', label: 'Kahraman', premium: true),
    ];

    return MasalPage(
      title: 'Ayarlar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appUser?.email.isNotEmpty == true
                        ? appUser!.email
                        : 'Hesap bilgisi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appUser == null
                        ? 'Kullanici bilgisi yukleniyor.'
                        : isAdmin
                        ? 'Yonetici erisimi acik.'
                        : isPremium
                        ? 'Premium aktif. Aylik $monthlyQuota masal hakki.'
                        : isTrialActive
                        ? '7 gunluk deneme aktif. Bitis: ${_formatDate(appUser.trialEndsAt)}'
                        : 'Ucretsiz plan. Aylik $monthlyQuota masal hakki ve reklamli deneyim.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (!isPremium && !isAdmin) ...[
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => context.push('/paywall'),
                      child: Text(
                        isTrialActive
                            ? 'Premium planlarini gor'
                            : 'Premiuma gec',
                      ),
                    ),
                  ],
                  if (isAdmin) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/admin'),
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      label: const Text('Admin paneli'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Masal sesi', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          GlassCard(
            borderRadius: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                children: voices.map((v) {
                  // MVP’de paywall kapalıysa kilitleme göstermeyelim; sadece TTS/UX test edilsin.
                  final disabled = enablePaywall
                      ? (!canAccessPremiumFeatures && v.premium)
                      : false;
                  final isSelected = voice == v.id;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: disabled
                          ? Colors.white38
                          : isSelected
                          ? AppColors.accentOrange
                          : Colors.white70,
                    ),
                    title: Text(v.label),
                    trailing: disabled
                        ? const Icon(
                            Icons.lock_outline,
                            color: AppColors.accentOrange,
                          )
                        : null,
                    enabled: !disabled,
                    onTap: disabled
                        ? () {}
                        : () {
                            ref
                                .read(childProfileProvider.notifier)
                                .setSelectedVoiceId(v.id);
                          },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            !enablePaywall
                ? 'MVP’de test için tüm sesler açık.'
                : isPremium
                ? 'Premium tüm sesler açık.'
                : 'Ücretsiz kullanıcı için bazı sesler kilitli.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textBase.withValues(alpha: 0.75),
            ),
          ),
          const Spacer(),
          MasalBottomNav(currentTab: ParentTab.settings),
        ],
      ),
    );
  }
}

class _VoiceOption {
  const _VoiceOption({
    required this.id,
    required this.label,
    required this.premium,
  });
  final String id;
  final String label;
  final bool premium;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
