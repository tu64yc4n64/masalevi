import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/models/app_user_model.dart';
import '../firebase/users_repository_api.dart';

final userRoleProvider = Provider<AppUserRole>((ref) {
  return ref.watch(currentAppUserProvider)?.role ?? AppUserRole.user;
});

final isOwnerProvider = Provider<bool>((ref) {
  return ref.watch(userRoleProvider) == AppUserRole.owner;
});

final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(userRoleProvider);
  return role == AppUserRole.admin || role == AppUserRole.owner;
});
