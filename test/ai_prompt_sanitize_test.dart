import 'package:flutter_test/flutter_test.dart';

import 'package:masal_evi/core/services/ai/ai_story_service.dart';

void main() {
  test('sanitizeAiRequest whitelist theme/value uygular', () {
    final req = AiStoryRequest(
      childName: '<b>Ece</b>\n',
      age: 99,
      gender: 'kiz<script>',
      theme: 'NotAllowedTheme',
      value: 'NotAllowedValue',
      length: StoryLength.medium,
    );

    final safe = sanitizeAiRequest(req);

    expect(safe.childName, isNot(contains('<')));
    expect(safe.age, 10); // clamp 2-10
    expect(safe.gender, 'Kız');

    // fallback: allowed list'in ilk elemanı
    expect(safe.theme, 'Orman macerası');
    expect(safe.value, 'Dürüstlük');
  });
}

