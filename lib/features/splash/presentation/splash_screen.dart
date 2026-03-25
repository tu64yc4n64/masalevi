import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/masal_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
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

