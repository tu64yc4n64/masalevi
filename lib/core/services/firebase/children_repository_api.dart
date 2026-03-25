import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/feature_flags.dart';
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
    final values = _store[userId]?.values.toList(growable: false) ?? const [];
    return values;
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

class FirestoreChildrenRepositoryApi implements ChildrenRepositoryApi {
  FirestoreChildrenRepositoryApi(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _children(String userId) {
    return _firestore.collection('users').doc(userId).collection('children');
  }

  @override
  Future<ChildModel?> getChild({
    required String userId,
    required String childId,
  }) async {
    final snapshot = await _children(userId).doc(childId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ChildModel.fromMap(childId: childId, map: data);
  }

  @override
  Future<List<ChildModel>> getChildren({required String userId}) async {
    final snapshot = await _children(userId).get();
    final children = snapshot.docs
        .map((doc) => ChildModel.fromMap(childId: doc.id, map: doc.data()))
        .toList(growable: false);
    children.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return children;
  }

  @override
  Stream<ChildModel?> watchChild({
    required String userId,
    required String childId,
  }) {
    return _children(userId).doc(childId).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return ChildModel.fromMap(childId: childId, map: data);
    });
  }

  @override
  Stream<List<ChildModel>> watchChildren({required String userId}) {
    return _children(userId).snapshots().map((snapshot) {
      final children = snapshot.docs
          .map((doc) => ChildModel.fromMap(childId: doc.id, map: doc.data()))
          .toList(growable: false);
      children.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return children;
    });
  }

  @override
  Future<void> upsertChild({
    required String userId,
    required ChildModel child,
  }) async {
    await _children(
      userId,
    ).doc(child.childId).set(child.toMap(), SetOptions(merge: true));
  }
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
  return FirestoreChildrenRepositoryApi(FirebaseFirestore.instance);
});

final childrenListProvider = StreamProvider<List<ChildModel>>((ref) {
  final flags = ref.watch(featureFlagsProvider);
  final user = ref.watch(currentFirebaseUserProvider);
  if (flags.useMockRepositories || user == null) {
    return Stream<List<ChildModel>>.value(const []);
  }
  return ref
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
