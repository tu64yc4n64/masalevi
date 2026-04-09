import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/services/firebase/auth/firebase_auth_service.dart';
import '../../children/application/child_profile_controller.dart';

class StoryPlayerState {
  const StoryPlayerState({
    required this.isPlaying,
    required this.activeWordIndex,
  });

  final bool isPlaying;
  final int activeWordIndex;

  StoryPlayerState copyWith({bool? isPlaying, int? activeWordIndex}) {
    return StoryPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
    );
  }
}

class StoryPlayerController extends Notifier<StoryPlayerState> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  File? _cachedAudioFile;

  @override
  StoryPlayerState build() {
    // Kullanıcı sayfadan geri/çıkınca TTS'in devam etmesini istemiyoruz.
    ref.onDispose(() {
      _tts.stop();
      _audioPlayer.stop();
      _audioPlayer.dispose();
      final cachedAudioFile = _cachedAudioFile;
      if (cachedAudioFile != null) {
        () async {
          try {
            await cachedAudioFile.delete();
          } catch (_) {}
        }();
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      state = state.copyWith(isPlaying: false);
    });
    return const StoryPlayerState(isPlaying: false, activeWordIndex: 0);
  }

  List<int> _computeWordStartCharIndices(String text) {
    // UI tarafında da `split(RegExp(r'\s+'))` kullanıyoruz; karakter bazlı başlangıç indekslerini
    // aynı şekilde `\S+` ile çıkaralım ki TTS ilerleme callback'i ile eşleşsin.
    final matches = RegExp(r'\S+').allMatches(text);
    return matches.map((m) => m.start).toList(growable: false);
  }

  int _findWordIndexFromCharStart(
    List<int> wordStartCharIndices,
    int charStart,
  ) {
    if (wordStartCharIndices.isEmpty) {
      return 0;
    }
    if (charStart <= wordStartCharIndices.first) {
      return 0;
    }
    if (charStart >= wordStartCharIndices.last) {
      return wordStartCharIndices.length - 1;
    }

    // Binary search: wordStart <= charStart < sonrakiWordStart
    int low = 0;
    int high = wordStartCharIndices.length - 1;
    int ans = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (wordStartCharIndices[mid] <= charStart) {
        ans = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    return ans;
  }

  Future<void> play({
    required String text,
    required int wordCount,
    String? audioUrl,
  }) async {
    state = state.copyWith(isPlaying: true, activeWordIndex: 0);

    if (wordCount <= 0 || text.trim().isEmpty) {
      state = state.copyWith(isPlaying: false);
      return;
    }

    if (audioUrl != null && audioUrl.isNotEmpty) {
      try {
        final bytes = await _fetchAudioBytes(audioUrl);
        final file = await _writeAudioFile(bytes);
        _cachedAudioFile = file;
        await _audioPlayer.stop();
        await _audioPlayer.play(
          DeviceFileSource(file.path, mimeType: 'audio/mpeg'),
        );
        return;
      } catch (_) {
        // Remote audio yoksa mevcut TTS yedeğine düş.
      }
    }

    final effectiveWordStartIndices = _computeWordStartCharIndices(text);
    final effectiveWordCount = effectiveWordStartIndices.length;
    if (effectiveWordCount <= 0) {
      state = state.copyWith(isPlaying: false);
      return;
    }

    final voiceId = ref.read(childProfileProvider)?.selectedVoiceId ?? 'Burcu';
    final (pitch, rate) = _voiceConfig(voiceId);

    // TTS ayarları: MVP’de farklı sesleri pitch/rate ile simüle ediyoruz.
    await _tts.setLanguage('tr-TR');
    await _tts.setPitch(pitch);
    await _tts.setSpeechRate(rate);

    // Kelime highlight'i sabit süreyle değil, TTS'in bildirdiği gerçek ilerleme ile yapıyoruz.
    _tts.setProgressHandler((String fullText, int start, int end, String word) {
      if (effectiveWordCount <= 0) return;
      final nextIndex = _findWordIndexFromCharStart(
        effectiveWordStartIndices,
        start,
      );
      if (nextIndex < 0 || nextIndex >= effectiveWordCount) return;
      if (nextIndex == state.activeWordIndex) return;
      state = state.copyWith(activeWordIndex: nextIndex);
    });

    _tts.setCompletionHandler(() {
      state = state.copyWith(isPlaying: false);
    });

    await _tts.speak(text);
  }

  Future<void> pause() async {
    state = state.copyWith(isPlaying: false);
    await _tts.stop();
    await _audioPlayer.stop();
  }

  Future<Uint8List> _fetchAudioBytes(String audioUrl) async {
    final baseUrl = ref.read(backendConfigProvider).baseUrl;
    final token = ref.read(firebaseAuthServiceProvider).currentSessionToken;
    final resolvedUrl = audioUrl.startsWith('http')
        ? audioUrl
        : '$baseUrl$audioUrl';
    final response = await http.get(
      Uri.parse(resolvedUrl),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Masal sesi alinamadi: ${response.statusCode}');
    }
    return response.bodyBytes;
  }

  Future<File> _writeAudioFile(Uint8List bytes) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/masal_audio_${DateTime.now().microsecondsSinceEpoch}.mp3';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  (double pitch, double rate) _voiceConfig(String voiceId) {
    switch (voiceId) {
      case 'peri_ana':
        return (1.08, 0.45);
      case 'sevgi_teyze':
        return (0.95, 0.38);
      case 'kahraman':
        return (1.02, 0.42);
      case 'dede':
        return (0.86, 0.36);
      default:
        return (1.0, 0.40);
    }
  }
}

final storyPlayerControllerProvider =
    NotifierProvider.autoDispose<StoryPlayerController, StoryPlayerState>(
      StoryPlayerController.new,
    );
