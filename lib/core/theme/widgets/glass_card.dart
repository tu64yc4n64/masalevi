import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 18,
    this.borderOpacity = 0.35,
  });

  final Widget child;
  final double borderRadius;
  final double borderOpacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        // GlassCard içinde buton okunabilirliği düşmesin diye blur/opacity'i azaltıyoruz.
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withOpacity(0.38),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.primaryPurple.withOpacity(borderOpacity)),
          ),
          child: child,
        ),
      ),
    );
  }
}

