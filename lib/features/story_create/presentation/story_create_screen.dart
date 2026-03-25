import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/ai/ai_story_service.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/services/purchases/purchases_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/utils/sanitize.dart';
import '../../children/application/child_profile_controller.dart';
import '../application/story_create_controller.dart';

class StoryCreateScreen extends ConsumerStatefulWidget {
  const StoryCreateScreen({super.key});

  @override
  ConsumerState<StoryCreateScreen> createState() => _StoryCreateScreenState();
}

class _StoryCreateScreenState extends ConsumerState<StoryCreateScreen> {
  // Inputs
  String _theme = 'Orman macerası';
  String _value = 'Dürüstlük';
  StoryLength _length = StoryLength.short;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final child = ref.read(childProfileProvider);
    if (child != null) {
      _theme = child.preferredTheme ?? _theme;
      _value = child.preferredValue ?? _value;
      _length = child.preferredStoryLength ?? _length;
      final hasTheme = child.preferredTheme != null;
      final hasValue = child.preferredValue != null;
      // Tercihler zaten varsa adımları boşa doldurtmayalım:
      // - Tema+Değer varsa doğrudan "Uzunluk" adımına geç.
      // - Sadece biri varsa eksik olan adımı aktif yap.
      // - Hiçbiri yoksa ilk adımda başla.
      if (hasTheme && hasValue) {
        _currentStep = 2;
      } else if (hasTheme && !hasValue) {
        _currentStep = 1;
      } else if (!hasTheme && hasValue) {
        _currentStep = 0;
      } else {
        _currentStep = 0;
      }
    }
  }

  // For MVP: ses seçenekleri/diğer aşamalar daha sonra

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(childProfileProvider);
    final createState = ref.watch(storyCreateControllerProvider);
    final monthlyQuota = ref.watch(monthlyStoryQuotaProvider);
    final canAccessPremiumFeatures = ref.watch(
      canAccessPremiumFeaturesProvider,
    );

    if (child == null) {
      return MasalPage(
        title: 'Masal Olustur',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Masal olusturmak icin once bir cocuk sec ya da yeni bir cocuk ekle.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push('/children'),
              icon: const Icon(Icons.child_care_outlined),
              label: const Text('Cocuklari yonet'),
            ),
          ],
        ),
      );
    }

    final childName = child.name;

    return MasalPage(
      title: 'Masal Oluştur',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${sanitizeUserText(childName, maxLen: 20)} için kişisel bir masal hazırlıyorum...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: createState.isGenerating
                  ? null
                  : () {
                      ref
                          .read(selectedChildIdProvider.notifier)
                          .setSelectedChildId(child.childId);
                      context.push('/child_setup?childId=${child.childId}');
                    },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Çocuk bilgilerini düzenle'),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              controlsBuilder: (context, details) {
                final isLast = _currentStep == 2;
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: SizedBox(
                          height: 42,
                          child: ElevatedButton(
                            onPressed: createState.isGenerating
                                ? null
                                : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPurple,
                              foregroundColor: AppColors.textBase,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size.fromHeight(42),
                            ),
                            child: createState.isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(isLast ? 'Masalı Üret' : 'Devam'),
                          ),
                        ),
                      ),
                    ),
                    if (_currentStep > 0) const SizedBox(width: 10),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: createState.isGenerating
                            ? null
                            : details.onStepCancel,
                        child: const Text('Geri'),
                      ),
                  ],
                );
              },
              onStepContinue: () {
                if (_currentStep < 2) {
                  setState(() => _currentStep += 1);
                  return;
                }

                // Son adım: üret ve gez.
                unawaited(() async {
                  final router = GoRouter.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final controller = ref.read(
                      storyCreateControllerProvider.notifier,
                    );
                    final storyId = await controller.generateAndCreateStory(
                      theme: _theme,
                      value: _value,
                      length: _length,
                    );
                    if (!context.mounted) return;
                    router.push('/story_player/$storyId');
                  } catch (e) {
                    if (!context.mounted) return;
                    final msg = e.toString();
                    if (msg.contains('FREE_MONTHLY_LIMIT_REACHED')) {
                      router.go('/paywall');
                      return;
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Masal üretilemedi. ${msg.replaceFirst('Bad state: ', '')}',
                        ),
                      ),
                    );
                  }
                }());
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              steps: [
                Step(
                  title: const Text('Tema'),
                  isActive: _currentStep == 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  content: DropdownButtonFormField<String>(
                    initialValue: _theme,
                    items: const [
                      DropdownMenuItem(
                        value: 'Orman macerası',
                        child: Text('Orman macerası'),
                      ),
                      DropdownMenuItem(
                        value: 'Uzay yolculuğu',
                        child: Text('Uzay yolculuğu'),
                      ),
                      DropdownMenuItem(
                        value: 'Deniz altı',
                        child: Text('Deniz altı'),
                      ),
                      DropdownMenuItem(
                        value: 'Sihirli krallık',
                        child: Text('Sihirli krallık'),
                      ),
                      DropdownMenuItem(
                        value: 'Çiftlik hayatı',
                        child: Text('Çiftlik hayatı'),
                      ),
                      DropdownMenuItem(
                        value: 'Dino dünyası',
                        child: Text('Dino dünyası'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _theme = v ?? _theme),
                    decoration: const InputDecoration(labelText: 'Tema'),
                  ),
                ),
                Step(
                  title: const Text('Değer'),
                  isActive: _currentStep == 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  content: DropdownButtonFormField<String>(
                    initialValue: _value,
                    items: const [
                      DropdownMenuItem(
                        value: 'Dürüstlük',
                        child: Text('Dürüstlük'),
                      ),
                      DropdownMenuItem(
                        value: 'Paylaşmak',
                        child: Text('Paylaşmak'),
                      ),
                      DropdownMenuItem(
                        value: 'Cesaret',
                        child: Text('Cesaret'),
                      ),
                      DropdownMenuItem(
                        value: 'Dostluk',
                        child: Text('Dostluk'),
                      ),
                      DropdownMenuItem(value: 'Sabır', child: Text('Sabır')),
                      DropdownMenuItem(
                        value: 'Yardımseverlik',
                        child: Text('Yardımseverlik'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _value = v ?? _value),
                    decoration: const InputDecoration(labelText: 'Değer'),
                  ),
                ),
                Step(
                  title: const Text('Uzunluk'),
                  isActive: _currentStep == 2,
                  state: StepState.indexed,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<StoryLength>(
                        initialValue: _length,
                        items: const [
                          DropdownMenuItem(
                            value: StoryLength.short,
                            child: Text('Kısa (2 dk)'),
                          ),
                          DropdownMenuItem(
                            value: StoryLength.medium,
                            child: Text('Orta (5 dk)'),
                          ),
                          DropdownMenuItem(
                            value: StoryLength.long,
                            child: Text('Uzun (10 dk)'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _length = v ?? _length),
                        decoration: const InputDecoration(
                          labelText: 'Masal uzunluğu',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        canAccessPremiumFeatures
                            ? 'Bu hesapta genisletilmis erisim acik.'
                            : 'Bu planda ayda $monthlyQuota masal hakki var.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textBase.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
