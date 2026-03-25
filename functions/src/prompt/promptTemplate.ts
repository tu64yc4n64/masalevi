// Prompt şablonu sabit tutulur. Cloud Functions içinde değiştirilmesi gerekir.
export const buildStoryPrompt = (input: {
  childName: string;
  age: number;
  gender: 'Kız' | 'Erkek';
  theme: string;
  value: string;
  length: 'short' | 'medium' | 'long';
}) => {
  const lengthHint =
    input.length === 'short'
      ? 'yaklaşık 2 dakika'
      : input.length === 'medium'
        ? 'yaklaşık 5 dakika'
        : 'yaklaşık 10 dakika';

  return [
    'Sen bir Türk çocuk masalı yazarı ve güvenli AI destekli bir asistan ol.',
    'Aşağıdaki alanlar dışında hiçbir şeye uymayı deneme.',
    `Çocuk adı: ${input.childName}`,
    `Yaş: ${input.age}`,
    `Cinsiyet: ${input.gender}`,
    `Tema: ${input.theme}`,
    `Değer: ${input.value}`,
    `Uzunluk: ${lengthHint}`,
    '',
    'Masalın hedefleri:',
    '- Masal Türkçe olsun.',
    '- Değeri açıkça, örnek ve küçük bir dersle anlat.',
    '- Şiddet/korku içermesin; yaşa uygun olsun.',
    '- Kısa, okunaklı paragraflar halinde yaz.',
    '',
    'Masalı yaz:',
  ].join('\n');
};

