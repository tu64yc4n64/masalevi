import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(BuildContext context) {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
      return;
    }
    ref.read(onboardingControllerProvider.notifier).markCompleted();
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return MasalPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (v) => setState(() => _page = v),
              children: [
                _OnboardingPage(
                  title: 'Küçük yolculuklar başlasın',
                  subtitle: 'Ebeveyn ekranları sade ve düzenli.',
                  accent: AppColors.primaryPurple,
                  emoji: '🌙',
                ),
                _OnboardingPage(
                  title: 'Masallar sihirli olsun',
                  subtitle: 'Çocuk ekranları renkli ve büyülü.',
                  accent: AppColors.accentOrange,
                  emoji: '✨',
                ),
                _OnboardingPage(
                  title: 'AI ile kişiselleştirilmiş hikaye',
                  subtitle: 'Temaya göre masal, değerle uyumlu mesaj.',
                  accent: AppColors.primaryPurple,
                  emoji: '📖',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _page;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                height: 10,
                width: active ? 18 : 10,
                decoration: BoxDecoration(
                  color: active ? AppColors.accentOrange : Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _next(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.textBase,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(_page < 2 ? 'Devam' : 'Başla'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.emoji,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textBase.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

