import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/admin/presentation/admin_screen.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/children/presentation/children_screen.dart';
import 'features/children/presentation/child_profile_setup_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/paywall/presentation/paywall_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/story_create/presentation/story_create_screen.dart';
import 'features/story_player/presentation/story_player_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/child_setup',
        builder: (context, state) => ChildProfileSetupScreen(
          childId: state.uri.queryParameters['childId'],
        ),
      ),
      GoRoute(
        path: '/children',
        builder: (context, state) => const ChildrenScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/story_create',
        builder: (context, state) => const StoryCreateScreen(),
      ),
      GoRoute(
        path: '/story_player/:storyId',
        builder: (context, state) =>
            StoryPlayerScreen(
              storyId: state.pathParameters['storyId'] ?? '',
              initialVoiceId: state.uri.queryParameters['voiceId'],
              autoPlay: state.uri.queryParameters['autoplay'] == '1',
            ),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
    ],
  );
});
