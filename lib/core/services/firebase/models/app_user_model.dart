enum AppUserRole { user, admin, owner }

class AppUserModel {
  AppUserModel({
    required this.uid,
    required this.email,
    required this.isPremium,
    required this.storyCount,
    required this.storyResetDate,
    required this.trialStartedAt,
    required this.trialEndsAt,
    this.role = AppUserRole.user,
  });

  final String uid;
  final String email;
  final bool isPremium;
  final int storyCount;
  final DateTime storyResetDate;
  final DateTime trialStartedAt;
  final DateTime trialEndsAt;
  final AppUserRole role;

  bool get isAdminLike =>
      role == AppUserRole.admin || role == AppUserRole.owner;

  bool get isOwner => role == AppUserRole.owner;

  bool get isTrialActive => DateTime.now().isBefore(trialEndsAt);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'isPremium': isPremium,
      'storyCount': storyCount,
      'storyResetDate': storyResetDate.toIso8601String(),
      'trialStartedAt': trialStartedAt.toIso8601String(),
      'trialEndsAt': trialEndsAt.toIso8601String(),
      'role': role.name,
    };
  }

  static AppUserModel fromMap(String uid, Map<String, dynamic> map) {
    final role = (map['role'] as String?)?.toLowerCase();
    final parsedRole = role == 'owner'
        ? AppUserRole.owner
        : role == 'admin'
        ? AppUserRole.admin
        : AppUserRole.user;

    return AppUserModel(
      uid: (map['id'] as String?) ?? uid,
      email: (map['email'] as String?) ?? '',
      isPremium:
          (map['isPremium'] as bool?) ?? (map['is_premium'] as bool?) ?? false,
      storyCount:
          (map['storyCount'] as int?) ?? (map['story_count'] as int?) ?? 0,
      storyResetDate: _parseDateTime(
        map['storyResetDate'] ?? map['story_reset_date'],
      ),
      trialStartedAt: _parseDateTime(
        map['trialStartedAt'] ?? map['trial_started_at'],
      ),
      trialEndsAt: _parseDateTime(
        map['trialEndsAt'] ?? map['trial_ends_at'],
        fallback: DateTime.now().add(const Duration(days: 7)),
      ),
      role: parsedRole,
    );
  }
}

DateTime _parseDateTime(Object? value, {DateTime? fallback}) {
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }
  return fallback ?? DateTime.now();
}
