# GuffGaff AI

A ChatGPT-style AI chat app built with **Flutter + FastAPI + Google Gemini**.

Features a three-stage hybrid pipeline: curated manual answers → context-injected Gemini → pure Gemini fallback. Every response carries a source badge (**Manual / AI+Context / AI**).

---

## Project Structure

```
guffgaff_AI/
├── backend/              FastAPI backend
│   ├── app/
│   │   ├── config.py     env-driven settings
│   │   ├── main.py       FastAPI app + CORS + lifespan
│   │   ├── db/           SQLAlchemy async engine
│   │   ├── models/       ORM models (Session, Message)
│   │   ├── schemas/      Pydantic request/response schemas
│   │   ├── routes/       chat · sessions · manual · health
│   │   └── services/
│   │       ├── gemini_service.py    Gemini streaming wrapper
│   │       ├── manual_service.py   JSON knowledge base + scoring
│   │       └── chat_pipeline.py    Hybrid 3-stage orchestrator
│   ├── manual_data.json  Curated Q&A knowledge base
│   ├── .env.example
│   └── requirements.txt
└── lib/                  Flutter frontend
    ├── core/             constants · theme
    ├── data/
    │   ├── models/       SessionModel · MessageModel · ChatChunk
    │   └── services/     ApiService (HTTP + SSE streaming)
    ├── providers/        Riverpod: sessions · chat · theme
    └── presentation/
        ├── screens/      ChatScreen
        └── widgets/      MessageBubble · ChatInput · SessionsDrawer
                          SourceBadge · TypingIndicator
```

---

## Quick Start

### 1 — Add your Gemini API key

```bash
cd backend
cp .env.example .env
# Edit .env and set:  GEMINI_API_KEY=your_key_here
```

Get a free key at [aistudio.google.com](https://aistudio.google.com/app/apikey).

### 2 — Run the backend

```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The API is now live at `http://localhost:8000`.
Check `http://localhost:8000/health` to confirm.
Browse the interactive docs at `http://localhost:8000/docs`.

### 3 — Point Flutter at the backend

Open [lib/core/constants.dart](lib/core/constants.dart) and set `baseUrl`:

| Target | Value |
|---|---|
| Android emulator | `http://10.0.2.2:8000` (default) |
| iOS simulator or desktop | `http://localhost:8000` |
| Physical device | `http://<your-machine-LAN-IP>:8000` |

### 4 — Run the Flutter app

```bash
# From the project root (guffgaff_AI/)
flutter pub get
flutter run
```

---

## Chat Pipeline Logic

```
User message
      │
      ▼
 ManualService.search(message)
      │
      ├─ top score ≥ 0.72 ──► return curated answer   source = "manual"
      │
      ├─ any score ≥ 0.28 ──► inject top-3 entries     source = "gemini+context"
      │                        into Gemini system prompt
      │                        → stream Gemini reply
      │
      └─ no matches ────────► stream Gemini directly   source = "gemini"
```

Each streamed chunk is sent as an SSE event:
```json
{"text": "chunk...", "source": "gemini", "done": false}
```

The Flutter `ApiService` parses the SSE stream, `ChatNotifier` appends each chunk to the streaming message bubble in real-time, and the final bubble shows the source badge.

---

## Editing the Knowledge Base

### Via REST API (no restart needed)

```bash
# List all entries
curl http://localhost:8000/manual

# Add an entry
curl -X POST http://localhost:8000/manual \
  -H "Content-Type: application/json" \
  -d '{"question":"What is Flutter?","keywords":["flutter","dart","framework"],"answer":"Flutter is Google'\''s UI toolkit.","category":"tech"}'

# Update
curl -X PUT http://localhost:8000/manual/<id> \
  -H "Content-Type: application/json" \
  -d '{"answer":"Updated answer here."}'

# Delete
curl -X DELETE http://localhost:8000/manual/<id>
```

### Directly in `backend/manual_data.json`

Each entry:
```json
{
  "id": "unique-string",
  "question": "The canonical question",
  "keywords": ["keyword1", "keyword2"],
  "answer": "The curated answer shown to users.",
  "category": "any-label"
}
```

Restart the backend (or use the API) for JSON file edits to take effect.

---

## API Reference

| Method | Path | Description |
|---|---|---|
| `GET` | `/health` | Health check |
| `POST` | `/chat` | Stream a reply (SSE) |
| `GET` | `/sessions` | List all sessions |
| `POST` | `/sessions` | Create a session |
| `GET` | `/sessions/{id}` | Session + messages |
| `PUT` | `/sessions/{id}` | Rename session |
| `DELETE` | `/sessions/{id}` | Delete session |
| `GET` | `/manual` | List knowledge base |
| `POST` | `/manual` | Add entry |
| `PUT` | `/manual/{id}` | Update entry |
| `DELETE` | `/manual/{id}` | Delete entry |
