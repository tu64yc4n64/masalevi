import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/models/app_user_model.dart';
import '../../../core/services/firebase/users_repository_api.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../application/admin_controller.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminControllerProvider);
    final currentUser = ref.watch(currentAppUserProvider);

    if (!adminState.isAdmin) {
      return MasalPage(
        title: 'Yonetim',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bu sayfayi sadece yetkili hesaplar gorebilir.',
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
      title: 'Yonetim',
      child: usersAsync.when(
        data: (users) {
          final sortedUsers = [...users]..sort((a, b) {
            final emailA = a.email.trim().toLowerCase();
            final emailB = b.email.trim().toLowerCase();
            if (emailA.isEmpty && emailB.isEmpty) return a.uid.compareTo(b.uid);
            if (emailA.isEmpty) return 1;
            if (emailB.isEmpty) return -1;
            return emailA.compareTo(emailB);
          });

          final query = _searchQuery.trim().toLowerCase();
          final visibleUsers = sortedUsers.where((user) {
            if (query.isEmpty) return true;
            return user.email.toLowerCase().contains(query);
          }).toList(growable: false);

          final premiumCount = sortedUsers.where((user) => user.isPremium).length;
          final adminCount = sortedUsers.where((user) => user.role == AppUserRole.admin).length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                adminState.isOwner
                    ? 'Kullanicilar burada e-posta adresleriyle listelenir. Premium ve yonetim yetkilerini buradan duzenleyebilirsin.'
                    : 'Kullanicilar burada e-posta adresleriyle listelenir. Premium erisimlerini buradan duzenleyebilirsin.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              GlassCard(
                borderRadius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kullanici ara',
                          hintText: 'E-posta ile ara',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(label: 'Toplam ${sortedUsers.length}'),
                          _InfoChip(label: 'Premium $premiumCount'),
                          if (adminState.isOwner)
                            _InfoChip(label: 'Yonetim $adminCount'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: visibleUsers.isEmpty
                    ? Center(
                        child: Text(
                          query.isEmpty
                              ? 'Henuz kullanici yok.'
                              : 'Bu aramayla eslesen kullanici bulunamadi.',
                        ),
                      )
                    : ListView.separated(
                        itemCount: visibleUsers.length,
                        separatorBuilder: (_, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = visibleUsers[index];
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.email.isEmpty ? user.uid : user.email,
                                              style: Theme.of(context).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _StatusChip(
                                                  label: _roleLabel(user.role),
                                                  color: AppColors.primaryPurple,
                                                ),
                                                if (user.isPremium)
                                                  const _StatusChip(
                                                    label: 'Premium',
                                                    color: AppColors.accentOrange,
                                                  ),
                                                if (user.isTrialActive && !user.isPremium)
                                                  const _StatusChip(
                                                    label: 'Trial',
                                                    color: Colors.blueAccent,
                                                  ),
                                                if (isCurrentUser)
                                                  const _StatusChip(
                                                    label: 'Bu hesap',
                                                    color: Colors.white24,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Premium'),
                                    subtitle: Text(
                                      user.isPremium
                                          ? 'Uygulama premium olarak acik.'
                                          : 'Ucretsiz planda gorunuyor.',
                                    ),
                                    value: user.isPremium,
                                    onChanged: canEditPremium
                                        ? (value) async {
                                            await ref
                                                .read(adminControllerProvider.notifier)
                                                .setPremium(uid: user.uid, isPremium: value);
                                          }
                                        : null,
                                  ),
                                  if (adminState.isOwner)
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: const Text('Yonetim yetkisi'),
                                      subtitle: const Text(
                                        'Bu kullanici uygulamadaki yonetim sayfasini gorebilir.',
                                      ),
                                      value: user.role == AppUserRole.admin,
                                      onChanged: canEditRole
                                          ? (value) async {
                                              await ref
                                                  .read(adminControllerProvider.notifier)
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
          );
        },
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(label),
    );
  }
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.owner:
      return 'Owner';
    case AppUserRole.admin:
      return 'Yonetim';
    case AppUserRole.user:
      return 'Kullanici';
  }
}
