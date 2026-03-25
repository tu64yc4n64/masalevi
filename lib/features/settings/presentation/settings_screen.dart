import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/auth/firebase_auth_service.dart';
import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/services/purchases/purchases_service.dart';
import '../../../core/services/tts/tts_voice_service.dart';
import '../../../core/services/user/user_role_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_bottom_nav.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../children/application/child_profile_controller.dart';
import '../../../core/config/feature_flags.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _voiceSearchController = TextEditingController();
  String _voiceQuery = '';

  @override
  void dispose() {
    _voiceSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(childProfileProvider);
    final appUser = ref.watch(currentAppUserProvider);
    final voice = profile?.selectedVoiceId ?? 'sevgi_teyze';
    final isPremium = ref.watch(isPremiumProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final enablePaywall = ref.watch(featureFlagsProvider).enablePaywall;
    final voicesAsync = ref.watch(elevenLabsVoicesProvider);

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
                      label: const Text('Yonetim'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _voiceSearchController,
                    onChanged: (value) {
                      setState(() => _voiceQuery = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'ElevenLabs sesi ara',
                      hintText: 'Ses adiyla ara',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 12),
                  voicesAsync.when(
                    data: (voices) {
                      final query = _voiceQuery.trim().toLowerCase();
                      final filteredVoices = voices.where((voiceOption) {
                        if (query.isEmpty) return true;
                        return voiceOption.name.toLowerCase().contains(query);
                      }).toList(growable: false);

                      if (filteredVoices.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Text('Bu aramaya uygun ses bulunamadi.'),
                        );
                      }

                      return SizedBox(
                        height: 260,
                        child: ListView.builder(
                          itemCount: filteredVoices.length,
                          itemBuilder: (context, index) {
                            final voiceOption = filteredVoices[index];
                            final isSelected = voice == voiceOption.id;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? AppColors.accentOrange
                                    : Colors.white70,
                              ),
                              title: Text(voiceOption.name),
                              subtitle: Text(
                                [
                                  if (voiceOption.language?.isNotEmpty == true)
                                    voiceOption.language!,
                                  if (voiceOption.category?.isNotEmpty == true)
                                    voiceOption.category!,
                                ].join(' • '),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.accentOrange,
                                    )
                                  : null,
                              onTap: () {
                                ref
                                    .read(childProfileProvider.notifier)
                                    .setSelectedVoiceId(voiceOption.id);
                              },
                            );
                          },
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text('ElevenLabs sesleri yuklenemedi.\n$error'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            !enablePaywall
                ? 'ElevenLabs sesleri test icin acik.'
                : isPremium
                ? 'Premium kullanici olarak tum secili sesleri test edebilirsin.'
                : 'Sesleri burada deneyip daha sonra kalici secimi netlestirebiliriz.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textBase.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(firebaseAuthServiceProvider).signOut();
              if (!context.mounted) return;
              context.go('/auth');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cikis Yap'),
          ),
          const Spacer(),
          MasalBottomNav(currentTab: ParentTab.settings),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
