enum ChildGender { kiz, erkek, other }

class ChildModel {
  ChildModel({
    required this.childId,
    required this.name,
    required this.age,
    required this.gender,
    required this.interests,
    this.emojiAvatar = '🙂',
    this.preferredTheme,
    this.preferredValue,
    this.selectedVoiceId = 'Burcu',
  });

  final String childId;
  final String name;
  final int age;
  final ChildGender gender;
  final List<String> interests;
  final String emojiAvatar;
  final String? preferredTheme;
  final String? preferredValue;
  final String selectedVoiceId;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender.name,
      'interests': interests,
      'emojiAvatar': emojiAvatar,
      'preferredTheme': preferredTheme,
      'preferredValue': preferredValue,
      'selectedVoiceId': selectedVoiceId,
    };
  }

  static ChildModel fromMap({
    required String childId,
    required Map<String, dynamic> map,
  }) {
    final genderRaw = (map['gender'] as String?)?.toLowerCase();
    final gender = genderRaw == 'kız'
        ? ChildGender.kiz
        : genderRaw == 'erkek'
        ? ChildGender.erkek
        : ChildGender.other;

    return ChildModel(
      childId: childId,
      name: (map['name'] as String?) ?? '',
      age: (map['age'] as int?) ?? 2,
      gender: gender,
      interests:
          (map['interests'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      emojiAvatar: (map['emojiAvatar'] as String?) ?? '🙂',
      preferredTheme: map['preferredTheme'] as String?,
      preferredValue: map['preferredValue'] as String?,
      selectedVoiceId: (map['selectedVoiceId'] as String?) ?? 'Burcu',
    );
  }
}
