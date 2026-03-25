import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/api_client.dart';

class TtsVoice {
  const TtsVoice({
    required this.id,
    required this.name,
    this.previewUrl,
    this.category,
    this.language,
  });

  final String id;
  final String name;
  final String? previewUrl;
  final String? category;
  final String? language;

  factory TtsVoice.fromMap(Map<String, dynamic> map) {
    final labels = map['labels'] as Map<String, dynamic>?;
    return TtsVoice(
      id: map['voice_id'] as String? ?? '',
      name: map['name'] as String? ?? 'Voice',
      previewUrl: map['preview_url'] as String?,
      category: map['category'] as String?,
      language: labels?['language'] as String?,
    );
  }
}

final elevenLabsVoicesProvider = FutureProvider<List<TtsVoice>>((ref) async {
  final response = await ref.read(apiClientProvider).getJson('/tts/voices');
  return (response['voices'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(TtsVoice.fromMap)
      .toList(growable: false);
});
