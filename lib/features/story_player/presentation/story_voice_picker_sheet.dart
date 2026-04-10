import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    builder: (context) => _StoryVoicePickerSheet(
      initialVoiceId: initialVoiceId,
      title: title,
    ),
  );
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
    final voicesAsync = ref.watch(elevenLabsVoicesProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Flexible(
              child: voicesAsync.when(
                data: (voices) {
                  final normalizedQuery = _query.toLowerCase();
                  final filtered = voices.where((voice) {
                    if (normalizedQuery.isEmpty) return true;
                    return voice.name.toLowerCase().contains(normalizedQuery);
                  }).toList(growable: false);
                  if (filtered.isEmpty) {
                    return const Center(child: Text('Ses bulunamadi.'));
                  }
                  return ListView.builder(
                    shrinkWrap: true,
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
                error: (error, _) => Center(child: Text('Sesler yuklenemedi.\n$error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
