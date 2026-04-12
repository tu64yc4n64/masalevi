import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import '../backend/api_client.dart';
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
  Future<AppUserModel?> uploadVoiceSample({
    required String audioBase64,
    required String mimeType,
    required String sampleScript,
  });
  Future<AppUserModel?> deleteVoiceSample();
}

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
    yield _store.values.toList(growable: false);
  }

  @override
  Future<void> ensureUser({
    required String uid,
    required String? email,
  }) async {}

  @override
  Future<void> incrementStoryCount({required String uid}) async {}

  @override
  Future<void> setPremium({
    required String uid,
    required bool isPremium,
  }) async {}

  @override
  Future<void> setUserRole({
    required String uid,
    required AppUserRole role,
  }) async {}

  @override
  Future<AppUserModel?> uploadVoiceSample({
    required String audioBase64,
    required String mimeType,
    required String sampleScript,
  }) async => null;

  @override
  Future<AppUserModel?> deleteVoiceSample() async => null;
}

class BackendUsersRepositoryApi implements UsersRepositoryApi {
  BackendUsersRepositoryApi(this._ref);

  final Ref _ref;

  ApiClient get _client => _ref.read(apiClientProvider);

  @override
  Future<AppUserModel?> getUser(String uid) async {
    final currentUser = _ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return null;

    if (currentUser.uid == uid) {
      final response = await _client.getJson('/users/me');
      final userMap = response['user'] as Map<String, dynamic>? ?? const {};
      return AppUserModel.fromMap(uid, userMap);
    }

    final users = await _fetchUsers();
    for (final user in users) {
      if (user.uid == uid) return user;
    }
    return null;
  }

  @override
  Stream<AppUserModel?> watchUser(String uid) async* {
    yield await getUser(uid);
  }

  @override
  Stream<List<AppUserModel>> watchUsers() async* {
    yield await _fetchUsers();
  }

  Future<List<AppUserModel>> _fetchUsers() async {
    final response = await _client.getJson('/users');
    final users = (response['users'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((map) => AppUserModel.fromMap(map['id'] as String? ?? '', map))
        .toList(growable: false);
    return users;
  }

  @override
  Future<void> ensureUser({
    required String uid,
    required String? email,
  }) async {}

  @override
  Future<void> incrementStoryCount({required String uid}) async {
    refetchUsers(_ref);
  }

  @override
  Future<void> setPremium({
    required String uid,
    required bool isPremium,
  }) async {
    await _client.patchJson(
      '/users/$uid/premium',
      body: {'isPremium': isPremium},
    );
    refetchUsers(_ref);
  }

  @override
  Future<void> setUserRole({
    required String uid,
    required AppUserRole role,
  }) async {
    await _client.patchJson('/users/$uid/role', body: {'role': role.name});
    refetchUsers(_ref);
  }

  @override
  Future<AppUserModel?> uploadVoiceSample({
    required String audioBase64,
    required String mimeType,
    required String sampleScript,
  }) async {
    final response = await _client.postJson(
      '/users/me/voice-sample',
      body: {
        'audioBase64': audioBase64,
        'mimeType': mimeType,
        'sampleScript': sampleScript,
      },
    );
    refetchUsers(_ref);
    final userMap = response['user'] as Map<String, dynamic>? ?? const {};
    if (userMap.isEmpty) return null;
    return AppUserModel.fromMap(userMap['id'] as String? ?? '', userMap);
  }

  @override
  Future<AppUserModel?> deleteVoiceSample() async {
    final response = await _client.deleteJson('/users/me/voice-sample');
    refetchUsers(_ref);
    final userMap = response['user'] as Map<String, dynamic>? ?? const {};
    if (userMap.isEmpty) return null;
    return AppUserModel.fromMap(userMap['id'] as String? ?? '', userMap);
  }
}

class UsersRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final usersRefreshProvider = NotifierProvider<UsersRefreshNotifier, int>(
  UsersRefreshNotifier.new,
);

void refetchUsers(Ref ref) {
  ref.read(usersRefreshProvider.notifier).bump();
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
  return BackendUsersRepositoryApi(ref);
});

final currentAppUserStreamProvider = StreamProvider<AppUserModel?>((
  ref,
) async* {
  ref.watch(usersRefreshProvider);
  final authUser = ref.watch(currentFirebaseUserProvider);
  if (authUser == null) {
    yield null;
    return;
  }
  yield await ref.watch(usersRepositoryApiProvider).getUser(authUser.uid);
});

final currentAppUserProvider = Provider<AppUserModel?>((ref) {
  return ref.watch(currentAppUserStreamProvider).value;
});

final allUsersStreamProvider = StreamProvider<List<AppUserModel>>((ref) async* {
  ref.watch(usersRefreshProvider);
  yield* ref.watch(usersRepositoryApiProvider).watchUsers();
});
