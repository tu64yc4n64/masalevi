import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase/models/app_user_model.dart';
import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/services/user/user_role_service.dart';

class AdminState {
  const AdminState({required this.isAdmin, required this.isOwner});

  final bool isAdmin;
  final bool isOwner;
}

class AdminController extends Notifier<AdminState> {
  @override
  AdminState build() {
    return AdminState(
      isAdmin: ref.watch(isAdminProvider),
      isOwner: ref.watch(isOwnerProvider),
    );
  }

  Future<void> setPremium({required String uid, required bool isPremium}) {
    return ref
        .read(usersRepositoryApiProvider)
        .setPremium(uid: uid, isPremium: isPremium);
  }

  Future<void> setRole({required String uid, required AppUserRole role}) {
    return ref
        .read(usersRepositoryApiProvider)
        .setUserRole(uid: uid, role: role);
  }
}

final adminControllerProvider = NotifierProvider<AdminController, AdminState>(
  AdminController.new,
);
