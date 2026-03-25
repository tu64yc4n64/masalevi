import 'package:flutter/material.dart';

import '../app_colors.dart';
import 'bounce_button.dart';

/// Devam(Mock) ile aynı görsel dili kullanan ana aksiyon butonu.
class MasalPrimaryButton extends StatelessWidget {
  const MasalPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final safeOnTap = enabled ? onPressed! : () {};

    final gradientColors = enabled
        ? const [AppColors.primaryPurple, AppColors.accentOrange]
        : [
            AppColors.primaryPurple.withOpacity(0.35),
            AppColors.accentOrange.withOpacity(0.22),
          ];
    final textColor = enabled ? AppColors.textBase : AppColors.textBase.withOpacity(0.7);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: BounceButton(
        onTap: safeOnTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

