import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/tts/tts_voice_service.dart';

Future<String?> showStoryVoicePickerSheet(
  BuildContext context,
  WidgetRef ref, {
  String? initialVoiceId,
  String title = 'Masal sesi sec',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(
          top: mediaQuery.padding.top + 18,
          left: 10,
          right: 10,
          bottom: 8,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: mediaQuery.size.height * 0.72,
            ),
            child: _StoryVoicePickerSheet(
              initialVoiceId: initialVoiceId,
              title: title,
            ),
          ),
        ),
      );
    },
  );
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navyBackground,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.35),
        ),
      ),
      child: child,
    );
  }
}

class _StoryVoicePickerSheet extends ConsumerStatefulWidget {
  const _StoryVoicePickerSheet({
    required this.initialVoiceId,
    required this.title,
  });

  final String? initialVoiceId;
  final String title;

  @override
  ConsumerState<_StoryVoicePickerSheet> createState() =>
      _StoryVoicePickerSheetState();
}

class _StoryVoicePickerSheetState
    extends ConsumerState<_StoryVoicePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voicesAsync = ref.watch(ttsVoicesProvider);
    return _SheetScaffold(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Ses ara',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: voicesAsync.when(
                data: (voices) {
                  final normalizedQuery = _query.toLowerCase();
                  final filtered = voices
                      .where((voice) {
                        if (normalizedQuery.isEmpty) return true;
                        return voice.name.toLowerCase().contains(
                          normalizedQuery,
                        );
                      })
                      .toList(growable: false);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('Ses bulunamadi.'));
                  }
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final voice = filtered[index];
                      final isSelected = widget.initialVoiceId == voice.id;
                      return ListTile(
                        title: Text(voice.name),
                        subtitle: Text(
                          [
                            if (voice.language?.isNotEmpty == true)
                              voice.language!,
                            if (voice.category?.isNotEmpty == true)
                              voice.category!,
                          ].join(' • '),
                        ),
                        trailing: isSelected ? const Icon(Icons.check) : null,
                        onTap: () => Navigator.of(context).pop(voice.id),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Sesler yuklenemedi.\n$error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
