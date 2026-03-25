import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/ai/ai_story_service.dart';
import '../../../core/services/firebase/auth/firebase_auth_service.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/services/firebase/models/child_model.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/utils/sanitize.dart';

class ChildProfile {
  ChildProfile({
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    this.preferredTheme,
    this.preferredValue,
    this.preferredStoryLength,
    this.selectedVoiceId = 'sevgi_teyze',
  });

  final String childId;
  final String name;
  final int age;
  final String gender;
  final List<String> interests;
  final String? preferredTheme;
  final String? preferredValue;
  final StoryLength? preferredStoryLength;
  final String selectedVoiceId;
}

class ChildProfileController extends Notifier<ChildProfile?> {
  @override
  ChildProfile? build() {
    final flags = ref.watch(featureFlagsProvider);
    if (flags.useMockRepositories) return null;

    final childModel = ref.watch(activeChildModelProvider);
    if (childModel == null) return null;

    return ChildProfile(
      childId: childModel.childId,
      name: childModel.name,
      age: childModel.age,
      gender: childModel.gender.name == 'kiz'
          ? 'Kız'
          : childModel.gender.name == 'erkek'
          ? 'Erkek'
          : 'Diğer',
      interests: childModel.interests,
      preferredTheme: childModel.preferredTheme,
      preferredValue: childModel.preferredValue,
      selectedVoiceId: childModel.selectedVoiceId,
    );
  }

  Future<void> setProfile({
    required String childId,
    required String name,
    required int age,
    required String gender,
    required List<String> interests,
    String? preferredTheme,
    String? preferredValue,
    StoryLength? preferredStoryLength,
    String? selectedVoiceId,
  }) async {
    final safeName = sanitizeUserText(name, maxLen: 24);
    final safeGender = sanitizeUserText(gender, maxLen: 12);
    final profile = ChildProfile(
      childId: childId,
      name: safeName,
      age: age,
      gender: safeGender,
      interests: interests.map((e) => sanitizeUserText(e, maxLen: 20)).toList(),
      preferredTheme: preferredTheme,
      preferredValue: preferredValue,
      preferredStoryLength: preferredStoryLength,
      selectedVoiceId:
          selectedVoiceId ?? state?.selectedVoiceId ?? 'sevgi_teyze',
    );
    state = profile;

    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) {
      throw StateError('Firebase kullanicisi bulunamadi.');
    }

    await ref
        .read(childrenRepositoryApiProvider)
        .upsertChild(userId: user.uid, child: _toChildModel(profile));
    ref.read(selectedChildIdProvider.notifier).setSelectedChildId(childId);
  }

  Future<void> setSelectedVoiceId(String voiceId) async {
    final current = state;
    if (current == null) return;
    final updated = current.copyWithSelectedVoice(voiceId);
    state = updated;

    final user = ref.read(currentFirebaseUserProvider);
    if (user == null) return;
    unawaited(
      ref
          .read(childrenRepositoryApiProvider)
          .upsertChild(userId: user.uid, child: _toChildModel(updated)),
    );
  }

  void clear() => state = null;
}

extension on ChildProfile {
  ChildProfile copyWithSelectedVoice(String selectedVoiceId) {
    return ChildProfile(
      childId: childId,
      name: name,
      age: age,
      gender: gender,
      interests: interests,
      preferredTheme: preferredTheme,
      preferredValue: preferredValue,
      preferredStoryLength: preferredStoryLength,
      selectedVoiceId: selectedVoiceId,
    );
  }
}

ChildModel _toChildModel(ChildProfile profile) {
  return ChildModel(
    childId: profile.childId,
    name: profile.name,
    age: profile.age,
    gender: _mapGender(profile.gender),
    interests: profile.interests,
    preferredTheme: profile.preferredTheme,
    preferredValue: profile.preferredValue,
    selectedVoiceId: profile.selectedVoiceId,
  );
}

ChildGender _mapGender(String rawGender) {
  final gender = rawGender.toLowerCase();
  if (gender.contains('kız') || gender.contains('kiz')) {
    return ChildGender.kiz;
  }
  if (gender.contains('erkek')) {
    return ChildGender.erkek;
  }
  return ChildGender.other;
}

final childProfileProvider =
    NotifierProvider<ChildProfileController, ChildProfile?>(
      ChildProfileController.new,
    );

final emojiAvatarForGenderProvider = Provider<String>((ref) {
  final profile = ref.watch(childProfileProvider);
  if (profile == null) return '🙂';
  return profile.gender.toLowerCase().contains('kız') ? '👧' : '🧒';
});
