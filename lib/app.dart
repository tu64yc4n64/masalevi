import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_router.dart';
import 'core/theme/masal_theme.dart';

class MasalEviApp extends ConsumerWidget {
  const MasalEviApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Masal Evi',
      theme: MasalTheme.dark().toMaterialTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}

