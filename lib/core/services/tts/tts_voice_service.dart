import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../backend/api_client.dart';
import '../firebase/users_repository_api.dart';

const customUserVoiceId = 'custom_user_voice';
const customUserVoiceSampleScript =
    'Merhaba. Benim sesimle anlatilan sicacik bir masal dinlemek istiyorum. Masal Evi ile hayal kurmak cok guzel.';

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

final availableTtsVoicesProvider = FutureProvider<List<TtsVoice>>((ref) async {
  final response = await ref.read(apiClientProvider).getJson('/tts/voices');
  final voices = (response['voices'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(TtsVoice.fromMap)
      .toList(growable: false);

  final appUser = ref.watch(currentAppUserProvider);
  if (appUser?.hasCustomVoiceSample == true) {
    return [
      const TtsVoice(
        id: customUserVoiceId,
        name: 'Benim Sesim',
        category: 'Kisisel Ses Beta',
        language: 'tr-TR',
      ),
      ...voices,
    ];
  }

  return voices;
});

final elevenLabsVoicesProvider = availableTtsVoicesProvider;
