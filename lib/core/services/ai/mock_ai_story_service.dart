import 'dart:math';

import 'ai_story_service.dart';

class MockAiStoryService implements AiStoryService {
  @override
  Future<AiStoryResult> generateStory(AiStoryRequest request) async {
    // MVP stub: deterministik bir masal üretir.
    final title = 'Masal: ${request.theme}';
    final name = request.childName;
    final value = request.value;

    final lengthTokens = switch (request.length) {
      StoryLength.short => 45,
      StoryLength.medium => 85,
      StoryLength.long => 140,
    };

    final nouns = [
      'hilal',
      'yıldız',
      'ışık',
      'rüzgar',
      'kitap',
      'peri',
      'kahraman',
      'ejderha',
      'gemi',
      'orman',
    ];
    final rnd = Random(name.hashCode ^ value.hashCode ^ request.age);
    final words = <String>[];

    words.add(
      '$name küçük bir yolcu olarak ${request.theme.toLowerCase()} içine adım attı.',
    );
    words.add(
      'Kalbi ${request.gender.toLowerCase()} gibi zarif, gözleri ${value.toLowerCase()} için umut doluydu.',
    );

    while (words.join(' ').split(' ').length < lengthTokens) {
      final pick = nouns[rnd.nextInt(nouns.length)];
      words.add(
        'Bir anda $pick belirdi ve masal ${value.toLowerCase()} dersini fısıldadı.',
      );
    }

    final content = words.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    // UI animasyonlarını göstermek için küçük gecikme.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    return AiStoryResult(storyId: null, title: title, content: content);
  }
}
