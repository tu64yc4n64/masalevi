import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import '../quota/story_quota_utils.dart';
import 'auth/firebase_auth_service.dart';
import 'models/app_user_model.dart';

abstract class UsersRepositoryApi {
  Future<AppUserModel?> getUser(String uid);
  Stream<AppUserModel?> watchUser(String uid);
  Stream<List<AppUserModel>> watchUsers();
  Future<void> ensureUser({required String uid, required String? email});
  Future<void> setUserRole({required String uid, required AppUserRole role});
  Future<void> setPremium({required String uid, required bool isPremium});
  Future<void> incrementStoryCount({required String uid});
}

/// MVP stub: In-memory kullanıcı dokusu.
class MockUsersRepositoryApi implements UsersRepositoryApi {
  MockUsersRepositoryApi(this._store);

  final Map<String, AppUserModel> _store;

  @override
  Future<AppUserModel?> getUser(String uid) async => _store[uid];

  @override
  Stream<AppUserModel?> watchUser(String uid) async* {
    yield _store[uid];
  }

  @override
  Stream<List<AppUserModel>> watchUsers() async* {
    final users = _store.values.toList(growable: false)
      ..sort((a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
    yield users;
  }

  @override
  Future<void> ensureUser({required String uid, required String? email}) async {
    final now = DateTime.now();
    final normalizedEmail = (email ?? '').trim().toLowerCase();
    _store.putIfAbsent(
      uid,
      () => AppUserModel(
        uid: uid,
        email: normalizedEmail,
        isPremium: false,
        storyCount: 0,
        storyResetDate: computeNextResetDate(now),
        trialStartedAt: now,
        trialEndsAt: now.add(const Duration(days: 7)),
        role: AppUserRole.user,
      ),
    );
  }

  @override
  Future<void> setUserRole({
    required String uid,
    required AppUserRole role,
  }) async {
    final prev = _store[uid];
    if (prev == null) return;
    _store[uid] = AppUserModel(
      uid: prev.uid,
      email: prev.email,
      isPremium: prev.isPremium,
      storyCount: prev.storyCount,
      storyResetDate: prev.storyResetDate,
      trialStartedAt: prev.trialStartedAt,
      trialEndsAt: prev.trialEndsAt,
      role: role,
    );
  }

  @override
  Future<void> setPremium({
    required String uid,
    required bool isPremium,
  }) async {
    final prev = _store[uid];
    if (prev == null) return;
    _store[uid] = AppUserModel(
      uid: prev.uid,
      email: prev.email,
      isPremium: isPremium,
      storyCount: prev.storyCount,
      storyResetDate: prev.storyResetDate,
      trialStartedAt: prev.trialStartedAt,
      trialEndsAt: prev.trialEndsAt,
      role: prev.role,
    );
  }

  @override
  Future<void> incrementStoryCount({required String uid}) async {
    final prev = _store[uid];
    if (prev == null) return;
    _store[uid] = AppUserModel(
      uid: prev.uid,
      email: prev.email,
      isPremium: prev.isPremium,
      storyCount: prev.storyCount + 1,
      storyResetDate: prev.storyResetDate,
      trialStartedAt: prev.trialStartedAt,
      trialEndsAt: prev.trialEndsAt,
      role: prev.role,
    );
  }
}

class FirestoreUsersRepositoryApi implements UsersRepositoryApi {
  FirestoreUsersRepositoryApi(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Future<AppUserModel?> getUser(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUserModel.fromMap(uid, data);
  }

  @override
  Stream<AppUserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUserModel.fromMap(uid, data);
    });
  }

  @override
  Stream<List<AppUserModel>> watchUsers() {
    return _users.snapshots().map((snapshot) {
      final users = snapshot.docs
          .map((doc) => AppUserModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
      users.sort(
        (a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
      );
      return users;
    });
  }

  @override
  Future<void> ensureUser({required String uid, required String? email}) async {
    final existing = await getUser(uid);
    final normalizedEmail = (email ?? '').trim().toLowerCase();

    if (existing == null) {
      final now = DateTime.now();
      final user = AppUserModel(
        uid: uid,
        email: normalizedEmail,
        isPremium: false,
        storyCount: 0,
        storyResetDate: computeNextResetDate(now),
        trialStartedAt: now,
        trialEndsAt: now.add(const Duration(days: 7)),
        role: AppUserRole.user,
      );
      await _users.doc(uid).set(user.toMap());
      return;
    }

    final updates = <String, dynamic>{};
    if (normalizedEmail.isNotEmpty && existing.email != normalizedEmail) {
      updates['email'] = normalizedEmail;
    }
    if (updates.isNotEmpty) {
      await _users.doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  @override
  Future<void> incrementStoryCount({required String uid}) async {
    final docRef = _users.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final now = DateTime.now();
      final current = snapshot.exists && snapshot.data() != null
          ? AppUserModel.fromMap(uid, snapshot.data()!)
          : AppUserModel(
              uid: uid,
              email: '',
              isPremium: false,
              storyCount: 0,
              storyResetDate: computeNextResetDate(now),
              trialStartedAt: now,
              trialEndsAt: now.add(const Duration(days: 7)),
            );

      final resetNeeded = shouldReset(now, current.storyResetDate);
      final nextCount = (resetNeeded ? 0 : current.storyCount) + 1;
      final nextResetDate = resetNeeded
          ? computeNextResetDate(now)
          : current.storyResetDate;

      transaction.set(docRef, {
        'uid': uid,
        'email': current.email,
        'isPremium': current.isPremium,
        'storyCount': nextCount,
        'storyResetDate': Timestamp.fromDate(nextResetDate),
        'trialStartedAt': Timestamp.fromDate(current.trialStartedAt),
        'trialEndsAt': Timestamp.fromDate(current.trialEndsAt),
        'role': current.role.name,
      }, SetOptions(merge: true));
    });
  }

  @override
  Future<void> setPremium({
    required String uid,
    required bool isPremium,
  }) async {
    await _users.doc(uid).set({
      'isPremium': isPremium,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> setUserRole({
    required String uid,
    required AppUserRole role,
  }) async {
    await _users.doc(uid).set({'role': role.name}, SetOptions(merge: true));
  }
}

final _mockUsersStoreProvider = Provider<Map<String, AppUserModel>>(
  (ref) => <String, AppUserModel>{},
);

final usersRepositoryApiProvider = Provider<UsersRepositoryApi>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final store = ref.watch(_mockUsersStoreProvider);
  if (flags.useMockRepositories) {
    return MockUsersRepositoryApi(store);
  }
  return FirestoreUsersRepositoryApi(FirebaseFirestore.instance);
});

final currentAppUserStreamProvider = StreamProvider<AppUserModel?>((ref) {
  final firebaseUser = ref.watch(currentFirebaseUserProvider);
  if (firebaseUser == null) {
    return Stream<AppUserModel?>.value(null);
  }
  return ref.watch(usersRepositoryApiProvider).watchUser(firebaseUser.uid);
});

final currentAppUserProvider = Provider<AppUserModel?>((ref) {
  return ref.watch(currentAppUserStreamProvider).value;
});

final allUsersStreamProvider = StreamProvider<List<AppUserModel>>((ref) {
  return ref.watch(usersRepositoryApiProvider).watchUsers();
});
