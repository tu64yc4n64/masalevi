import 'package:cloud_firestore/cloud_firestore.dart';

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
      'storyResetDate': Timestamp.fromDate(storyResetDate),
      'trialStartedAt': Timestamp.fromDate(trialStartedAt),
      'trialEndsAt': Timestamp.fromDate(trialEndsAt),
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
      uid: uid,
      email: (map['email'] as String?) ?? '',
      isPremium: (map['isPremium'] as bool?) ?? false,
      storyCount: (map['storyCount'] as int?) ?? 0,
      storyResetDate:
          (map['storyResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trialStartedAt:
          (map['trialStartedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trialEndsAt:
          (map['trialEndsAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 7)),
      role: parsedRole,
    );
  }
}
