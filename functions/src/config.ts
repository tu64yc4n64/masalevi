export const AI_PROVIDER = process.env.AI_PROVIDER || 'groq';
export const TTS_PROVIDER = process.env.TTS_PROVIDER || 'elevenlabs';

export const GROQ_API_KEY = process.env.GROQ_API_KEY || '';
export const CLAUDE_API_KEY = process.env.CLAUDE_API_KEY || '';
export const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY || '';
export const AWS_ACCESS_KEY_ID = process.env.AWS_ACCESS_KEY_ID || '';
export const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY || '';
export const AWS_REGION = process.env.AWS_REGION || 'eu-central-1';

export const GROQ_MODEL = process.env.GROQ_MODEL || 'llama-3.3-70b-versatile';
export const CLAUDE_MODEL =
  process.env.CLAUDE_MODEL || 'claude-sonnet-4-20250514';
export const ELEVENLABS_MODEL =
  process.env.ELEVENLABS_MODEL || 'eleven_multilingual_v2';
export const POLLY_ENGINE = process.env.POLLY_ENGINE || 'neural';

// Tek endpoint URL yönetimi: Flutter tarafı `generateStoryEndpointUrl`
// üzerinden bu fonksiyonu çağırır.
export const GENERATE_STORY_HTTP_PATH = process.env.GENERATE_STORY_HTTP_PATH || '/generateStory';

// Optional: region/base URL tek yerden yönetmek için deploy config eklenecek.
export const FUNCTION_BASE_URL = process.env.FUNCTION_BASE_URL || '';
export const PORT = Number(process.env.PORT || 8080);
export const JWT_SECRET = process.env.JWT_SECRET || '';
