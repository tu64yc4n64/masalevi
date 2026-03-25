import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/backend_config.dart';
import '../../config/feature_flags.dart';
import '../firebase/auth/firebase_auth_service.dart';
import '../../utils/sanitize.dart';
import 'mock_ai_story_service.dart';
import 'cloud_functions_ai_story_service.dart';

enum StoryLength { short, medium, long }

class AiStoryRequest {
  AiStoryRequest({
    required this.childId,
    required this.childName,
    required this.age,
    required this.gender,
    required this.theme,
    required this.value,
    required this.length,
  });

  final String childId;
  final String childName;
  final int age;
  final String gender;
  final String theme;
  final String value;
  final StoryLength length;
}

class AiStoryResult {
  const AiStoryResult({
    this.storyId,
    required this.title,
    required this.content,
  });

  final String? storyId;
  final String title;
  final String content;
}

abstract class AiStoryService {
  Future<AiStoryResult> generateStory(AiStoryRequest request);
}

final aiStoryServiceProvider = Provider<AiStoryService>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final backend = ref.watch(backendConfigProvider);

  if (flags.useMockAiStoryService) {
    return MockAiStoryService();
  }

  // MVP’de varsayılan mock çalışır; gerçek endpoint geçişi için tek yer feature flag.
  return CloudFunctionsAiStoryService(
    generateStoryEndpointUrl: backend.generateStoryEndpointUrl,
    sessionToken: () =>
        ref.read(firebaseAuthServiceProvider).currentSessionToken,
  );
});

/// App tarafında da güvenlik için whitelist/sanitize (backend de aynı kontrolü yapmalı).
AiStoryRequest sanitizeAiRequest(AiStoryRequest request) {
  const allowedThemes = <String>[
    'Orman macerası',
    'Uzay yolculuğu',
    'Deniz altı',
    'Sihirli krallık',
    'Çiftlik hayatı',
    'Dino dünyası',
  ];
  const allowedValues = <String>[
    'Dürüstlük',
    'Paylaşmak',
    'Cesaret',
    'Dostluk',
    'Sabır',
    'Yardımseverlik',
  ];

  String pickAllowed(String raw, List<String> allowed, String defaultValue) {
    final clean = raw.trim().toLowerCase();
    for (final item in allowed) {
      if (item.toLowerCase() == clean) return item;
    }
    return defaultValue;
  }

  String normalizeGender(String raw) {
    final g = raw.trim().toLowerCase();
    // Türkçe karakterler prompt içinde oynanabilir; güvenli eşleme için kaba kontrol.
    if (g.contains('kız') || g.contains('kiz')) return 'Kız';
    return 'Erkek';
  }

  final safeThemeRaw = sanitizeUserText(request.theme, maxLen: 40);
  final safeValueRaw = sanitizeUserText(request.value, maxLen: 40);
  final safeGenderRaw = sanitizeUserText(request.gender, maxLen: 12);
  final safeName = sanitizeUserText(request.childName, maxLen: 24);

  return AiStoryRequest(
    childId: sanitizeUserText(request.childId, maxLen: 32),
    childName: safeName,
    age: sanitizeAge(request.age),
    gender: normalizeGender(safeGenderRaw),
    theme: pickAllowed(safeThemeRaw, allowedThemes, allowedThemes.first),
    value: pickAllowed(safeValueRaw, allowedValues, allowedValues.first),
    length: request.length,
  );
}
