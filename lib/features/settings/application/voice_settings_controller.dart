import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/tts/tts_voice_service.dart';

class VoiceSettings {
  const VoiceSettings({required this.selectedVoiceId});

  final String selectedVoiceId;
}

class VoiceSettingsController extends Notifier<VoiceSettings> {
  @override
  VoiceSettings build() =>
      const VoiceSettings(selectedVoiceId: defaultSystemVoiceId);

  void setVoice(String voiceId) {
    state = VoiceSettings(selectedVoiceId: voiceId);
  }
}

final voiceSettingsProvider =
    NotifierProvider<VoiceSettingsController, VoiceSettings>(
      VoiceSettingsController.new,
    );
