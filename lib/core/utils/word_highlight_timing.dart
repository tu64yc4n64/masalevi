int computeMsPerWord({
  required int totalDurationMs,
  required int wordCount,
}) {
  if (wordCount <= 0) return 0;
  final msPerWord = (totalDurationMs / wordCount).floor();
  return msPerWord <= 0 ? 1 : msPerWord;
}

/// Kelime highlight için her kelimenin yaklaşık başlangıç zamanını üretir.
///
/// MVP’de kelimeler arası süre eşit varsayılır. Gerçek TTS word-boundary
/// fonksiyonu eklenince bu fonksiyon daha hassas hale getirilebilir.
List<int> computeWordStartTimesMs({
  required int totalDurationMs,
  required String text,
}) {
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final wordCount = words.length;
  final msPerWord = computeMsPerWord(totalDurationMs: totalDurationMs, wordCount: wordCount);
  return List<int>.generate(wordCount, (i) => i * msPerWord);
}

