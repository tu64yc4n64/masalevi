import 'package:flutter_test/flutter_test.dart';

import 'package:masal_evi/core/utils/word_highlight_timing.dart';

void main() {
  test('computeMsPerWord hesaplaması', () {
    const wordCount = 3;
    const totalDurationMs = 720; // 3 * 240
    final msPerWord = computeMsPerWord(
      totalDurationMs: totalDurationMs,
      wordCount: wordCount,
    );
    expect(msPerWord, 240);
  });

  test('computeWordStartTimesMs eşit aralık üretir', () {
    const text = 'a b c';
    const wordCount = 3;
    const totalDurationMs = 720; // -> 240ms/kelime
    final starts = computeWordStartTimesMs(
      totalDurationMs: totalDurationMs,
      text: text,
    );
    expect(starts.length, wordCount);
    expect(starts, [0, 240, 480]);
  });
}

