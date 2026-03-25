import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/models/app_user_model.dart';
import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../application/admin_controller.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminControllerProvider);
    final currentUser = ref.watch(currentAppUserProvider);

    if (!adminState.isAdmin) {
      return MasalPage(
        title: 'Admin',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bu sayfayi sadece admin ve owner hesaplar gorebilir.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ana sayfaya don'),
            ),
          ],
        ),
      );
    }

    final usersAsync = ref.watch(allUsersStreamProvider);

    return MasalPage(
      title: 'Admin',
      child: usersAsync.when(
        data: (users) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              adminState.isOwner
                  ? 'Owner olarak premium ve admin yetkilerini yonetebilirsin.'
                  : 'Admin olarak kullanicilara premium acabilir veya kapatabilirsin.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: users.length,
                separatorBuilder: (_, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isCurrentUser = currentUser?.uid == user.uid;
                  final canEditRole =
                      adminState.isOwner &&
                      user.role != AppUserRole.owner &&
                      !isCurrentUser;
                  final canEditPremium =
                      user.role != AppUserRole.owner || adminState.isOwner;

                  return GlassCard(
                    borderRadius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.email.isEmpty
                                          ? user.uid
                                          : user.email,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Rol: ${_roleLabel(user.role)}${isCurrentUser ? ' • Bu hesap' : ''}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textBase
                                                .withValues(alpha: 0.72),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (user.isTrialActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPurple.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('Trial'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Premium'),
                            subtitle: Text(
                              user.isPremium
                                  ? 'Reklamsiz ve genis aylik hak acik.'
                                  : 'Ucretsiz planda kaliyor.',
                            ),
                            value: user.isPremium,
                            onChanged: canEditPremium
                                ? (value) async {
                                    await ref
                                        .read(adminControllerProvider.notifier)
                                        .setPremium(
                                          uid: user.uid,
                                          isPremium: value,
                                        );
                                  }
                                : null,
                          ),
                          if (adminState.isOwner)
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Admin'),
                              subtitle: const Text(
                                'Bu kullanici admin paneline girebilir.',
                              ),
                              value: user.role == AppUserRole.admin,
                              onChanged: canEditRole
                                  ? (value) async {
                                      await ref
                                          .read(
                                            adminControllerProvider.notifier,
                                          )
                                          .setRole(
                                            uid: user.uid,
                                            role: value
                                                ? AppUserRole.admin
                                                : AppUserRole.user,
                                          );
                                    }
                                  : null,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Geri'),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kullanicilar yuklenemedi.\n$error'),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Geri'),
            ),
          ],
        ),
      ),
    );
  }
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.owner:
      return 'owner';
    case AppUserRole.admin:
      return 'admin';
    case AppUserRole.user:
      return 'user';
  }
}
