const ALLOWED_THEMES = [
  'Orman macerası',
  'Uzay yolculuğu',
  'Deniz altı',
  'Sihirli krallık',
  'Çiftlik hayatı',
  'Dino dünyası',
];

const ALLOWED_VALUES = [
  'Dürüstlük',
  'Paylaşmak',
  'Cesaret',
  'Dostluk',
  'Sabır',
  'Yardımseverlik',
];

function stripUnsafe(input: unknown, maxLen: number) {
  const s = typeof input === 'string' ? input : '';
  const trimmed = s.trim();
  // Prompt injection azaltmak için temel temizlik.
  return trimmed
    .replace(/[\r\n]+/g, ' ')
    .replace(/[<>]/g, '')
    .replace(/[\u0000-\u001F]/g, '')
    .replace(/\s+/g, ' ')
    .slice(0, maxLen);
}

export type StoryLength = 'short' | 'medium' | 'long';

export function sanitizeStoryRequest(body: any): {
  childId: string;
  childName: string;
  age: number;
  gender: 'Kız' | 'Erkek';
  theme: string;
  value: string;
  length: StoryLength;
  selectedVoiceId: string;
} {
  const childId = stripUnsafe(body?.childId, 64) || 'unknown_child';
  const childName = stripUnsafe(body?.childName, 24) || 'Minik';
  const ageRaw = typeof body?.age === 'number' ? body.age : parseInt(body?.age, 10);
  const age = Math.min(10, Math.max(2, Number.isFinite(ageRaw) ? ageRaw : 5));

  const genderRaw = stripUnsafe(body?.gender, 12).toLowerCase();
  const gender = genderRaw.includes('kız') || genderRaw.includes('kiz') ? 'Kız' : 'Erkek';

  const themeRaw = stripUnsafe(body?.theme, 40);
  const theme =
    ALLOWED_THEMES.find((t) => t.toLowerCase() === themeRaw.toLowerCase()) ??
    ALLOWED_THEMES[0];

  const valueRaw = stripUnsafe(body?.value, 40);
  const value =
    ALLOWED_VALUES.find((v) => v.toLowerCase() === valueRaw.toLowerCase()) ??
    ALLOWED_VALUES[0];

  const lengthRaw = stripUnsafe(body?.length, 16) as string;
  const length: StoryLength =
    lengthRaw === 'medium' || lengthRaw === 'long' || lengthRaw === 'short'
      ? (lengthRaw as StoryLength)
      : 'short';
  const selectedVoiceId = stripUnsafe(body?.selectedVoiceId, 32) || 'sevgi_teyze';

  return { childId, childName, age, gender, theme, value, length, selectedVoiceId };
}
