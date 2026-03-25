import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
import '../backend/api_client.dart';
import 'auth/firebase_auth_service.dart';
import 'models/child_model.dart';

const primaryChildId = 'primary_child';

abstract class ChildrenRepositoryApi {
  Future<ChildModel?> getChild({
    required String userId,
    required String childId,
  });
  Future<List<ChildModel>> getChildren({required String userId});
  Stream<ChildModel?> watchChild({
    required String userId,
    required String childId,
  });
  Stream<List<ChildModel>> watchChildren({required String userId});
  Future<void> upsertChild({required String userId, required ChildModel child});
}

class MockChildrenRepositoryApi implements ChildrenRepositoryApi {
  MockChildrenRepositoryApi(this._store);

  final Map<String, Map<String, ChildModel>> _store;

  @override
  Future<ChildModel?> getChild({
    required String userId,
    required String childId,
  }) async {
    return _store[userId]?[childId];
  }

  @override
  Future<List<ChildModel>> getChildren({required String userId}) async {
    return _store[userId]?.values.toList(growable: false) ?? const [];
  }

  @override
  Stream<ChildModel?> watchChild({
    required String userId,
    required String childId,
  }) async* {
    yield _store[userId]?[childId];
  }

  @override
  Stream<List<ChildModel>> watchChildren({required String userId}) async* {
    yield _store[userId]?.values.toList(growable: false) ?? const [];
  }

  @override
  Future<void> upsertChild({
    required String userId,
    required ChildModel child,
  }) async {
    final userMap = _store[userId] ?? <String, ChildModel>{};
    userMap[child.childId] = child;
    _store[userId] = userMap;
  }
}

class BackendChildrenRepositoryApi implements ChildrenRepositoryApi {
  BackendChildrenRepositoryApi(this._ref);

  final Ref _ref;

  ApiClient get _client => _ref.read(apiClientProvider);

  @override
  Future<ChildModel?> getChild({
    required String userId,
    required String childId,
  }) async {
    try {
      final response = await _client.getJson('/children/$childId');
      final childMap = response['child'] as Map<String, dynamic>? ?? const {};
      return ChildModel.fromMap(childId: childId, map: _mapChild(childMap));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ChildModel>> getChildren({required String userId}) async {
    final response = await _client.getJson('/children');
    return (response['children'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (map) => ChildModel.fromMap(
            childId: map['id'] as String? ?? '',
            map: _mapChild(map),
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<ChildModel?> watchChild({
    required String userId,
    required String childId,
  }) async* {
    yield await getChild(userId: userId, childId: childId);
  }

  @override
  Stream<List<ChildModel>> watchChildren({required String userId}) async* {
    yield await getChildren(userId: userId);
  }

  @override
  Future<void> upsertChild({
    required String userId,
    required ChildModel child,
  }) async {
    await _client.putJson(
      '/children/${child.childId}',
      body: {
        'name': child.name,
        'age': child.age,
        'gender': child.gender.name,
        'interests': child.interests,
        'emojiAvatar': child.emojiAvatar,
        'preferredTheme': child.preferredTheme,
        'preferredValue': child.preferredValue,
        'selectedVoiceId': child.selectedVoiceId,
      },
    );
    refetchChildren(_ref);
  }

  Map<String, dynamic> _mapChild(Map<String, dynamic> map) {
    return {
      'name': map['name'],
      'age': map['age'],
      'gender': map['gender'],
      'interests': map['interests'],
      'emojiAvatar': map['emoji_avatar'] ?? map['emojiAvatar'],
      'preferredTheme': map['preferred_theme'] ?? map['preferredTheme'],
      'preferredValue': map['preferred_value'] ?? map['preferredValue'],
      'selectedVoiceId': map['selected_voice_id'] ?? map['selectedVoiceId'],
    };
  }
}

class ChildrenRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}

final childrenRefreshProvider = NotifierProvider<ChildrenRefreshNotifier, int>(
  ChildrenRefreshNotifier.new,
);

void refetchChildren(Ref ref) {
  ref.read(childrenRefreshProvider.notifier).bump();
}

final _mockChildrenStoreProvider =
    Provider<Map<String, Map<String, ChildModel>>>(
      (ref) => <String, Map<String, ChildModel>>{},
    );

final childrenRepositoryApiProvider = Provider<ChildrenRepositoryApi>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final store = ref.watch(_mockChildrenStoreProvider);
  if (flags.useMockRepositories) {
    return MockChildrenRepositoryApi(store);
  }
  return BackendChildrenRepositoryApi(ref);
});

final childrenListProvider = StreamProvider<List<ChildModel>>((ref) async* {
  ref.watch(childrenRefreshProvider);
  final user = ref.watch(currentFirebaseUserProvider);
  if (user == null) {
    yield const [];
    return;
  }
  yield* ref
      .watch(childrenRepositoryApiProvider)
      .watchChildren(userId: user.uid);
});

class SelectedChildIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSelectedChildId(String? childId) {
    state = childId;
  }
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildIdNotifier, String?>(
      SelectedChildIdNotifier.new,
    );

final activeChildIdProvider = Provider<String?>((ref) {
  final selected = ref.watch(selectedChildIdProvider);
  final children =
      ref.watch(childrenListProvider).value ?? const <ChildModel>[];
  if (selected != null && children.any((child) => child.childId == selected)) {
    return selected;
  }
  if (children.isEmpty) return null;
  return children.first.childId;
});

final activeChildModelProvider = Provider<ChildModel?>((ref) {
  final activeChildId = ref.watch(activeChildIdProvider);
  final children =
      ref.watch(childrenListProvider).value ?? const <ChildModel>[];
  if (activeChildId == null) return null;
  try {
    return children.firstWhere((child) => child.childId == activeChildId);
  } catch (_) {
    return null;
  }
});
