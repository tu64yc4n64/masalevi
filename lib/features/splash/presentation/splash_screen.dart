import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/services/firebase/auth/firebase_auth_service.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), _routeAfterSplash);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  Future<void> _routeAfterSplash() async {
    try {
      final authService = ref.read(firebaseAuthServiceProvider);
      await authService
          .ensureSessionRestored()
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;

      final user = authService.currentUser;
      if (user == null) {
        context.go('/onboarding');
        return;
      }

      final children = await ref
          .read(childrenRepositoryApiProvider)
          .getChildren(userId: user.uid)
          .timeout(const Duration(seconds: 5));
      if (!mounted) return;

      if (children.isEmpty) {
        context.go('/child_setup');
        return;
      }

      ref
          .read(selectedChildIdProvider.notifier)
          .setSelectedChildId(children.first.childId);
      context.go('/home');
    } catch (_) {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasalPage(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.nights_stay, size: 72, color: AppColors.accentOrange),
            const SizedBox(height: 14),
            Text(
              'Masal Evi',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 180,
              child: LottieBuilder.network(
                // Lottie json: MVP “animasyon varlığı” için remote stub.
                'https://assets10.lottiefiles.com/packages/lf20_touohxub.json',
                repeat: true,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.star_rounded, size: 72, color: AppColors.accentOrange));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
