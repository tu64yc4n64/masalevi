import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceSettings {
  const VoiceSettings({required this.selectedVoiceId});

  final String selectedVoiceId;
}

class VoiceSettingsController extends Notifier<VoiceSettings> {
  @override
  VoiceSettings build() => const VoiceSettings(selectedVoiceId: 'Burcu');

  void setVoice(String voiceId) {
    state = VoiceSettings(selectedVoiceId: voiceId);
  }
}

final voiceSettingsProvider =
    NotifierProvider<VoiceSettingsController, VoiceSettings>(
      VoiceSettingsController.new,
    );
