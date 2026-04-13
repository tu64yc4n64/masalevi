import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/users_repository_api.dart';

const customUserVoiceId = 'custom_user_voice';
const defaultSystemVoiceId = 'Burcu';
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
}

final ttsVoicesProvider = FutureProvider<List<TtsVoice>>((ref) async {
  final appUser = ref.watch(currentAppUserProvider);
  const systemVoice = TtsVoice(
    id: defaultSystemVoiceId,
    name: 'Varsayilan Ses',
    category: 'Sistem Sesi',
    language: 'tr-TR',
  );

  if (appUser?.hasCustomVoiceSample == true) {
    return const [
      systemVoice,
      TtsVoice(
        id: customUserVoiceId,
        name: 'Benim Sesim',
        category: 'Kisisel Ses Beta',
        language: 'tr-TR',
      ),
    ];
  }

  return const [systemVoice];
});
