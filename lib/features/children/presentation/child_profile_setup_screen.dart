import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/backend/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/widgets/glass_card.dart';
import '../../../core/theme/widgets/masal_primary_button.dart';
import '../../../core/theme/widgets/masal_page.dart';
import '../../../core/utils/sanitize.dart';
import '../../../core/services/firebase/children_repository_api.dart';
import '../../../core/services/firebase/models/child_model.dart';
import '../application/child_profile_controller.dart';

class ChildProfileSetupScreen extends ConsumerStatefulWidget {
  const ChildProfileSetupScreen({super.key, this.childId});

  final String? childId;

  @override
  ConsumerState<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState
    extends ConsumerState<ChildProfileSetupScreen> {
  static const _uuid = Uuid();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(text: '5');
  String _gender = 'Kız';
  String? _prefilledChildId;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final children =
        ref.watch(childrenListProvider).value ?? const <ChildModel>[];
    final editingChildId = widget.childId;
    final isFirstChildSetup = editingChildId == null && children.isEmpty;
    ChildModel? editingChild;
    if (editingChildId != null) {
      for (final child in children) {
        if (child.childId == editingChildId) {
          editingChild = child;
          break;
        }
      }
    }
    _prefillIfNeeded(editingChild);

    final emoji = _gender == 'Kız' ? '👧' : '🧒';
    final name = _nameController.text.trim();
    final parsedAge = int.tryParse(_ageController.text.trim());
    final nameValid = name.isNotEmpty;
    final ageValid = parsedAge != null && parsedAge >= 2 && parsedAge <= 10;
    final canSave = nameValid && ageValid;
    final isEditing = editingChildId != null;

    return MasalPage(
      title: isEditing ? 'Cocugu Duzenle' : 'Cocuk Profili',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 8),
                Text(
                  isEditing
                      ? 'Cocuk bilgilerini guncelle.'
                      : 'Cocuk bilgilerini ayarla.',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GlassCard(
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      'Isim, yas ve cinsiyet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'İsim',
                        hintText: 'Örn: Elif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _ageController,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Yaş',
                        hintText: '2-10',
                        helperText: ageValid
                            ? null
                            : 'Yaş 2 ile 10 arasında olmalı',
                        helperStyle: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Kız', child: Text('Kız')),
                        DropdownMenuItem(value: 'Erkek', child: Text('Erkek')),
                        DropdownMenuItem(value: 'Diğer', child: Text('Diğer')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? 'Kız'),
                      decoration: const InputDecoration(labelText: 'Cinsiyet'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: MasalPrimaryButton(
              label: 'Kaydet',
              onPressed: canSave
                  ? () async {
                      try {
                        final ageToSave = sanitizeAge(parsedAge);
                        final childIdToSave =
                            editingChildId ?? _uuid.v4();
                        await ref
                            .read(childProfileProvider.notifier)
                            .setProfile(
                              childId: childIdToSave,
                              name: name,
                              age: ageToSave,
                              gender: _gender,
                              // MVP: tema/değer/uzunluk masal oluştur sayfasında alınacak.
                              interests: const ['yıldız'],
                              preferredTheme: null,
                              preferredValue: null,
                              preferredStoryLength: null,
                            );
                      } on BackendApiException catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cocuk profili kaydedilemedi. ${error.message}',
                            ),
                          ),
                        );
                        return;
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cocuk profili kaydedilemedi. $error',
                            ),
                          ),
                        );
                        return;
                      }
                      if (!context.mounted) return;
                      context.go(isFirstChildSetup ? '/home' : '/children');
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kaydetmek için İsim boş olmasın ve Yaş 2-10 aralığında olsun.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textBase.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  void _prefillIfNeeded(ChildModel? child) {
    if (child == null) return;
    if (_prefilledChildId == child.childId) return;
    _prefilledChildId = child.childId;
    _nameController.text = child.name;
    _ageController.text = child.age.toString();
    _gender = switch (child.gender) {
      ChildGender.kiz => 'Kız',
      ChildGender.erkek => 'Erkek',
      ChildGender.other => 'Diğer',
    };
  }
}
