import 'package:flutter/material.dart';

import '../app_colors.dart';

class MasalPage extends StatelessWidget {
  const MasalPage({
    super.key,
    required this.child,
    this.title,
  });

  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      appBar: title == null
          ? null
          : AppBar(
              title: Text(title!),
              foregroundColor: AppColors.textBase,
              backgroundColor: Colors.transparent,
            ),
      body: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: child)),
    );
  }
}

