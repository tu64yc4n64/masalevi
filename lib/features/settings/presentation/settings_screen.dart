import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final AudioRecorder _audioRecorder = AudioRecorder();
  String _voiceQuery = '';
  bool _isRecordingVoiceSample = false;
  bool _isUploadingVoiceSample = false;
  String? _recordedVoiceSamplePath;

  @override
  void dispose() {
    _voiceSearchController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startVoiceSampleRecording() async {
    final messenger = ScaffoldMessenger.of(context);
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Mikrofon izni gerekli.')),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final filePath =
        '${tempDir.path}/voice_sample_${DateTime.now().microsecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: filePath,
    );
    if (!mounted) return;
    setState(() {
      _isRecordingVoiceSample = true;
      _recordedVoiceSamplePath = null;
    });
  }

  Future<void> _stopVoiceSampleRecording() async {
    final path = await _audioRecorder.stop();
    if (!mounted) return;
    setState(() {
      _isRecordingVoiceSample = false;
      _recordedVoiceSamplePath = path;
    });
  }

  Future<void> _uploadVoiceSample() async {
    final path = _recordedVoiceSamplePath;
    if (path == null || path.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isUploadingVoiceSample = true;
    });
    try {
      final bytes = await File(path).readAsBytes();
      await ref
          .read(usersRepositoryApiProvider)
          .uploadVoiceSample(
            audioBase64: base64Encode(bytes),
            mimeType: 'audio/m4a',
            sampleScript: customUserVoiceSampleScript,
          );
      await ref
          .read(childProfileProvider.notifier)
          .setSelectedVoiceId(customUserVoiceId);
      if (!mounted) return;
      setState(() {
        _recordedVoiceSamplePath = null;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ses ornegin kaydedildi. Artik Benim Sesim secilebilir.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Ses ornegi yuklenemedi. $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingVoiceSample = false;
        });
      }
    }
  }

  Future<void> _deleteVoiceSample() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(usersRepositoryApiProvider).deleteVoiceSample();
      final profile = ref.read(childProfileProvider);
      if (profile?.selectedVoiceId == customUserVoiceId) {
        await ref
            .read(childProfileProvider.notifier)
            .setSelectedVoiceId(defaultSystemVoiceId);
      }
      if (!mounted) return;
      setState(() {
        _recordedVoiceSamplePath = null;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Kayitli ses ornegi silindi.')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Ses ornegi silinemedi. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(childProfileProvider);
    final appUser = ref.watch(currentAppUserProvider);
    final voice = profile?.selectedVoiceId ?? defaultSystemVoiceId;
    final isPremium = ref.watch(isPremiumProvider);
    final isTrialActive = ref.watch(isTrialActiveProvider);
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final enablePaywall = ref.watch(featureFlagsProvider).enablePaywall;
    final voicesAsync = ref.watch(ttsVoicesProvider);

    return MasalPage(
      title: 'Ayarlar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                              icon: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              label: const Text('Yonetim'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kendi sesinle oku',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            appUser?.hasCustomVoiceSample == true
                                ? 'Kisisel ses ornegin hazir. Istersen Benim Sesim secenegiyle masallari kendi sesine yakin okutabiliriz.'
                                : 'Bir kez kisa ses ornegi alalim. Vazgecersen uygulama otomatik olarak varsayilan sistem sesine doner.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                            child: Text(
                              customUserVoiceSampleScript,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_recordedVoiceSamplePath != null)
                            Text(
                              'Kayit hazir. Yuklersen Benim Sesim secenegi aktif olacak.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isUploadingVoiceSample
                                      ? null
                                      : _isRecordingVoiceSample
                                      ? _stopVoiceSampleRecording
                                      : _startVoiceSampleRecording,
                                  icon: Icon(
                                    _isRecordingVoiceSample
                                        ? Icons.stop_circle_outlined
                                        : Icons.mic_none_rounded,
                                  ),
                                  label: Text(
                                    _isRecordingVoiceSample
                                        ? 'Kaydi bitir'
                                        : 'Ses testi baslat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_recordedVoiceSamplePath != null) ...[
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: _isUploadingVoiceSample
                                  ? null
                                  : _uploadVoiceSample,
                              icon: _isUploadingVoiceSample
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined),
                              label: Text(
                                _isUploadingVoiceSample
                                    ? 'Yukleniyor'
                                    : 'Ses ornegini yukle',
                              ),
                            ),
                          ],
                          if (appUser?.hasCustomVoiceSample == true) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => ref
                                  .read(childProfileProvider.notifier)
                                  .setSelectedVoiceId(customUserVoiceId),
                              icon: const Icon(
                                Icons.record_voice_over_outlined,
                              ),
                              label: const Text('Benim Sesim sec'),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _deleteVoiceSample,
                              child: const Text('Kayitli ses ornegini sil'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Masal sesi',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _voiceSearchController,
                            onChanged: (value) {
                              setState(() => _voiceQuery = value);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Ses ara',
                              hintText: 'Ses adiyla ara',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                          const SizedBox(height: 12),
                          voicesAsync.when(
                            data: (voices) {
                              final query = _voiceQuery.trim().toLowerCase();
                              final filteredVoices = voices
                                  .where((voiceOption) {
                                    if (query.isEmpty) return true;
                                    return voiceOption.name
                                        .toLowerCase()
                                        .contains(query);
                                  })
                                  .toList(growable: false);

                              if (filteredVoices.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 18),
                                  child: Text(
                                    'Bu aramaya uygun ses bulunamadi.',
                                  ),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
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
                                        if (voiceOption.language?.isNotEmpty ==
                                            true)
                                          voiceOption.language!,
                                        if (voiceOption.category?.isNotEmpty ==
                                            true)
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
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (error, _) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Text('Sesler yuklenemedi.\n$error'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    !enablePaywall
                        ? 'TTS sesleri test icin acik.'
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
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
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
