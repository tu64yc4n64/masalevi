import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/services/firebase/models/child_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_page.dart';

class ChildrenScreen extends ConsumerWidget {
  const ChildrenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);
    final activeChildId = ref.watch(activeChildIdProvider);

    return MasalPage(
      title: 'Cocuklar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Her cocuk icin ayri profil olusturabilir ve masallari secili cocuga gore yonetebilirsin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textBase.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: childrenAsync.when(
              data: (children) {
                if (children.isEmpty) {
                  return Center(
                    child: GlassCard(
                      borderRadius: 22,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.child_care_outlined,
                              size: 44,
                              color: AppColors.accentOrange,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Henuz cocuk profili yok.',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ilk profili olusturunca masallari o cocuga gore hazirlayacagiz.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push('/child_setup'),
                              icon: const Icon(Icons.add),
                              label: const Text('Ilk cocugu ekle'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: children.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final child = children[index];
                    final isSelected = child.childId == activeChildId;
                    return GlassCard(
                      borderRadius: 20,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primaryPurple
                                      .withValues(alpha: 0.25),
                                  child: Text(
                                    child.gender == ChildGender.kiz
                                        ? '👧'
                                        : '🧒',
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${child.age} yas',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textBase
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text('Secili'),
                                  ),
                              ],
                            ),
                            if (child.interests.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                child.interests.join(', '),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textBase.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: isSelected
                                        ? null
                                        : () {
                                            ref
                                                .read(
                                                  selectedChildIdProvider
                                                      .notifier,
                                                )
                                                .setSelectedChildId(
                                                  child.childId,
                                                );
                                            Navigator.of(context).maybePop();
                                          },
                                    child: Text(
                                      isSelected
                                          ? 'Bu cocuk acik'
                                          : 'Bu cocukla devam et',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(selectedChildIdProvider.notifier)
                                        .setSelectedChildId(child.childId);
                                    context.push(
                                      '/child_setup?childId=${child.childId}',
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Duzenle'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Cocuk profilleri yuklenemedi.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: () => context.push('/child_setup'),
              icon: const Icon(Icons.add),
              label: const Text('Yeni cocuk ekle'),
            ),
          ),
        ],
      ),
    );
  }
}
