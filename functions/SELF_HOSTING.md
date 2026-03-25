# Self-hosted AI backend

Bu klasor artik iki sekilde calisabilir:

1. Firebase Functions
2. Duz Node/Express sunucusu

## Gerekli env

`functions/.env` icine en az sunlari koy:

```env
AI_PROVIDER=groq
GROQ_API_KEY=your_groq_api_key_here
GROQ_MODEL=llama-3.3-70b-versatile
PORT=8080
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account","project_id":"masal-evi-b3a1e"}
```

`FIREBASE_SERVICE_ACCOUNT_JSON` alani Firebase service account JSON dosyasinin tek satir string halidir.

## Yerelde calistirma

```bash
cd functions
npm install
npm run build
npm start
```

Saglik kontrolu:

```bash
GET /health
```

Masal endpointi:

```bash
POST /generateStory
Authorization: Bearer <firebase_id_token>
Content-Type: application/json
```

## Flutter app'i sunucuya baglama

Uygulamayi kendi sunucuna baglamak icin:

```bash
flutter run --dart-define=FUNCTION_BASE_URL=https://api.senin-domainin.com
```

Uygulama varsayilan olarak `/generateStory` path'ini kullanir.

## Docker

```bash
cd functions
docker build -t masal-evi-ai .
docker run -p 8080:8080 --env-file .env masal-evi-ai
```
