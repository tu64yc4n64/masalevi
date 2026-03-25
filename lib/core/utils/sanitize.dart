String sanitizeUserText(String input, {required int maxLen}) {
  final trimmed = input.trim();
  // Prompt injection riskini azaltmak için temel zararlı karakterleri temizliyoruz.
  // Backend tarafında da aynı whitelist/escape uygulanmalı.
  final withoutNewlines = trimmed.replaceAll(RegExp(r'[\r\n]+'), ' ');
  final withoutControlChars = withoutNewlines.replaceAll(RegExp(r'[\u0000-\u001F]'), '');
  final noAngleBrackets = withoutControlChars.replaceAll('<', '').replaceAll('>', '');
  final collapsedSpaces = noAngleBrackets.replaceAll(RegExp(r'\s+'), ' ');
  return collapsedSpaces.length > maxLen ? collapsedSpaces.substring(0, maxLen) : collapsedSpaces;
}

int sanitizeAge(int age) {
  if (age < 2) return 2;
  if (age > 10) return 10;
  return age;
}

