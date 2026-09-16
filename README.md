# Baraza

Offline-first case-logging and advisory toolkit for community dispute mediators
(village elders, chiefs, WANEP/CIPP-trained mediators) in Kenya and Nigeria.

This is a **hackathon proof of concept** — it prioritizes a working end-to-end demo
over completeness, security hardening, or production data handling. See
"Known simplifications / next steps" at the bottom before using it for anything real.

## What it does

- Logs a dispute case in the field — including by voice (English/Swahili) — and
  saves it fully offline in under a minute. Speech-to-text dictation and real
  voice-note recordings are separate, independent inputs: dictation fills the
  typed description (needed for offline referral keyword-matching and the
  advisory search below), while recording keeps the actual audio itself,
  played back from the case detail screen. A case can have several separate
  voice-note recordings, not just one.
- Queues cases locally and syncs them to a backend automatically once the phone
  regains connectivity, or on demand via "Sync now". Sync never blocks the UI
  and never deletes/loses a local case.
- Looks up relevant law/policy for a case via retrieval-augmented search over a
  small seeded corpus (Kenya AJS Policy, Kenya land/succession/family Act
  excerpts, Nigeria Land Use Act, NigeriaLII customary court excerpts) and
  returns a short, **cited** summary — never a free-form LLM answer with no
  source. If the case has voice-note recordings, they're sent to Gemini
  alongside the text so the summary can factor in tone/detail the
  transcription might have missed — but citations still only ever come from
  the seeded corpus, never invented from the audio.
- Flags cases that look like they're outside what informal mediation should
  handle (repeat disputes, escalating violence, formal land title disputes,
  child protection concerns, possible criminal matters) and prompts a referral
  instead of letting the case close informally. The category list is a plain
  editable JSON config, not hidden model logic.
- Backend-backed accounts (register/sign in/sign out) so a mediator can
  recover their synced cases on a new or reinstalled device. Registering and
  signing in need connectivity once; logging cases stays fully offline
  afterward.

## Repo layout

```
backend/   NestJS + Prisma + MongoDB + Gemini — sync + advisory API
mobile/    Flutter (Android) app — Drift/SQLite local storage, offline-first
```

## Prerequisites

- Docker + Docker Compose (only needed for local backend dev — not for
  hosting on Render)
- A MongoDB connection string, pointed at a **replica set** (Prisma's MongoDB
  connector requires one, even a single-node one — a plain standalone
  `mongod` won't work). Any MongoDB Atlas cluster already satisfies this. For
  purely local dev, `docker compose up` spins up its own single-node replica
  set automatically, so you don't need one up front just to run locally.
- Flutter 3.44+ / Dart 3.12+ with the Android toolchain set up (mobile)
- A free [Gemini API key](https://aistudio.google.com/apikey) — used for
  embeddings (`gemini-embedding-001`) and the cited-summary generation
  (`gemini-2.5-flash` — deliberately **pinned**, not `gemini-flash-latest`:
  that alias returned transient 503 "high demand" errors often enough in
  testing to be unreliable for a live demo; `GeminiClient` also retries a
  few times with backoff on 503/429 before giving up, see "Architecture
  notes"). Gemini's model lineup moves fast — if either name stops working,
  check `GET https://generativelanguage.googleapis.com/v1beta/models?key=$GEMINI_API_KEY`
  for current model names supporting `embedContent` / `generateContent` and
  update `GEMINI_EMBEDDING_MODEL` / `GEMINI_GENERATION_MODEL`.
- An Android emulator or physical device

## 1. Run the backend locally

```bash
cd backend
cp .env.example .env
# edit .env: set GEMINI_API_KEY to your real key, and JWT_SECRET to any random string.
# Leave DATABASE_URL as the mongodb://mongo:27017/... default to use the bundled
# local Mongo container, or point it at your own connection string instead.
docker compose up -d --build
```

This starts MongoDB (as a single-node replica set — see `mongo-init` in
`docker-compose.yml`) and the NestJS API on `http://localhost:3000`. On boot
the container runs `prisma db push`, which syncs the Prisma schema's
collections/indexes into Mongo (Mongo has no SQL-style migration history —
`db push` just reconciles current schema vs. current database each time).

If you'd rather point the local backend straight at your own MongoDB (Atlas
or otherwise) instead of the bundled container, set `DATABASE_URL` in `.env`
to that connection string — include a database name in the path (e.g.
`.../baraza?appName=...`, right after the host and before the `?`), since
Atlas-style URIs otherwise omit it. Then start only the `backend` service
with `--no-deps` so Compose doesn't also spin up the unused local `mongo` /
`mongo-init` containers:
```bash
docker compose up -d --build --no-deps backend
```

Seed the corpus (embeds `backend/seed_data/*.txt` with Gemini and stores the
vectors) and a demo account + 3 example cases:

```bash
docker compose exec backend npm run seed
```

The seed script chunks each document by section, calls Gemini to embed every
chunk, and stores each chunk (including its embedding, as a plain float
array — see "Architecture notes" below) via Prisma. It also creates a demo
account (username `demo`, password `password123`) with 3 example cases —
separate from the on-device demo cases the mobile app seeds locally when you
register a new account.

**Note:** `backend/seed_data/*.txt` are short, clearly-labeled **placeholder**
excerpts written for this demo (see the disclaimer at the top of each file) —
not verbatim statutory text. Swap them for the real excerpts before relying on
this for anything beyond the demo.

Quick checks (`/sync/*` and `/advisory/query` need a Bearer token from
`/auth/login`; `/referral/categories` doesn't):

```bash
curl http://localhost:3000/referral/categories

TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "demo", "password": "password123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

curl -X POST http://localhost:3000/advisory/query \
  -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" \
  -d '{"description": "Two neighbors are fighting over a moved farm boundary fence"}'
```

## 2. Deploy the backend to Render

**Already deployed and live at `https://baraza.onrender.com`** — the mobile
app's default backend URL points there, so you don't need to do this step
just to run the app. These are the steps to redeploy it yourself, or update
it after a schema/env change.

Render has no native managed MongoDB — pair it with your own MongoDB
connection string (Atlas or otherwise; this repo doesn't assume which).

1. Push this repo to GitHub (Render deploys from a connected git repo).
2. In the Render dashboard: **New > Web Service**, connect the repo, set
   **Root Directory** to `backend`, and **Environment** to **Docker** (Render
   picks up `backend/Dockerfile` automatically).
3. Set these environment variables on the service:
   - `DATABASE_URL` — your MongoDB connection string (must resolve to a
     replica set, as above)
   - `GEMINI_API_KEY`
   - `GEMINI_EMBEDDING_MODEL` — `gemini-embedding-001` (or current equivalent)
   - `GEMINI_GENERATION_MODEL` — `gemini-2.5-flash` (pinned; avoid `-latest`
     aliases — see "Prerequisites" above)
   - `JWT_SECRET` — a long random string
   - Leave `PORT` unset — Render injects its own and `main.ts` already reads
     `process.env.PORT`
4. Deploy. Render builds the Dockerfile and runs its default `CMD` (`node
   dist/main.js`) — note this **skips** the `prisma db push` step that
   `docker-compose.yml`'s local dev `command:` adds, so the very first deploy
   needs the schema pushed once from your machine, pointed at the same
   database:
   ```bash
   cd backend
   DATABASE_URL="<your Render DATABASE_URL value>" npx prisma db push
   ```
   Re-run that (from anywhere, whenever the schema changes) rather than
   editing the Render service's start command — keeps `db push` an explicit,
   deliberate step instead of running unattended on every deploy.
5. Once deployed, run the seed script the same way — from your machine,
   pointed at the same database:
   ```bash
   cd backend
   DATABASE_URL="<your Render DATABASE_URL value>" GEMINI_API_KEY="<your key>" npm run seed
   ```
6. The backend URL is fixed in the app (not user-configurable — see
   `mobile/lib/services/backend_config.dart`). If you deploy to a different
   Render URL than the hardcoded `kBackendBaseUrl`, update that constant and
   rebuild.

Render's free tier spins the service down after inactivity — the first
request after a while will be slow (cold start) while it wakes back up.

## 3. Run the mobile app

```bash
cd mobile
flutter pub get
flutter run   # pick your emulator/device
```

The app's backend URL is fixed at build time (not user-configurable in the
app) — it points at the live Render deployment
(`https://baraza.onrender.com`), so no config is needed on any device. Render's
free tier spins down after inactivity — the first request after a while is
slow (cold start) while it wakes back up.

For local backend dev instead (`docker compose up` in `backend/`), change
`kBackendBaseUrl` in `mobile/lib/services/backend_config.dart` to
`http://10.0.2.2:3000` (Android **emulator** alias for your host machine) or
your computer's LAN IP (**physical device** on the same Wi-Fi, e.g.
`http://192.168.1.23:3000`), then rebuild.

First launch shows a **Sign In** screen. Either:
- Tap **Register** and create a new account (username, password, full name,
  country, region, locality) — the app then seeds 3 example cases locally so
  there's something to look at immediately, or
- Sign in with the seeded demo account: username `demo`, password
  `password123` (after running `docker compose exec backend npm run seed`) —
  the Sign In screen is pre-filled with these, so it's just a tap once you've
  hosted and seeded a backend. This pulls that account's 3 example cases down.

Registering and signing in need connectivity; logging cases afterward works
fully offline.

## Demo script

1. **Register or sign in** (needs connectivity once) — see above.
2. **Log a case offline** — turn on airplane mode, tap **New case**, fill in
   case type / parties (roles only, e.g. "Complainant", "Neighbor") / location
   / description (try **Dictate** — English or Kiswahili), optionally tap
   **Record** under "Voice notes" one or more times to attach real
   recordings, then save. The case appears in the list marked **Pending**.
3. **Trigger a referral flag** — log a case whose description mentions e.g.
   "he threatened me" or "this is the third time" — the app immediately shows
   a referral dialog and the case gets a flag banner on its detail screen,
   entirely offline (on-device keyword rules from `assets/config/referral_categories.json`).
4. **Sync** — turn Wi-Fi back on, open **Sync status**, tap **Sync now** (or
   just wait — it syncs automatically once connectivity returns). The case
   flips to **Synced** with a timestamp.
5. **Ask for guidance** — open any case, tap **Ask for guidance**. The backend
   embeds the description, retrieves the closest excerpt(s) from the seeded
   corpus by cosine similarity, and returns a short summary that cites the
   source document/section — considering any attached voice-note recordings
   too, not just their transcribed text. If nothing in the corpus is a close
   enough match, it says so instead of guessing — it never falls back to
   general knowledge without a citation.
6. **Sign out and recover on a "new" device** — open **Sync status** and tap
   **Sign out** (only allowed once everything's synced — it'll block and offer
   **Sync now** first if not). This clears the local case cache. Sign back in
   with the same account and the cases are pulled straight back down from the
   backend — the same recovery flow a mediator would get on a replacement
   phone.

## Data model (mobile, mirrored server-side)

`Case`: id, mediatorId, caseType, parties (roles only, JSON), description,
voiceNoteRefs (list — a case can have several separate recordings), location,
createdAt, syncedAt (nullable), referralFlag, referralReason, advisoryResponse
(last lookup result, JSON). Mobile stores the same fields locally in
`snake_case`-free Drift columns (see `mobile/lib/db/database.dart`, where the
list is JSON-encoded into `voiceNoteRefsJson`); the backend's MongoDB
documents use a native `voiceNoteRefs: String[]` field (see
`backend/prisma/schema.prisma`).

## Architecture notes

- **Gemini reliability**: `backend/src/gemini/gemini-client.ts` retries
  `embed`/`generate`/`generateWithAudio` up to 3 times with exponential
  backoff on HTTP 503/429 — Gemini's free tier returns transient "high
  demand" 503s occasionally, and a mediator tapping "Ask for guidance"
  shouldn't see a 500 for something that would succeed moments later.
  `GEMINI_GENERATION_MODEL` is also deliberately pinned to `gemini-2.5-flash`
  rather than a `-latest` alias for the same reason (see "Prerequisites").
- **Backend URL is fixed, not user-configurable** — `kBackendBaseUrl` in
  `mobile/lib/services/backend_config.dart` is a hardcoded constant; there's
  no in-app setting to change it. Change the constant and rebuild if you need
  to point at a different backend.
- **Auth**: `backend/src/auth/` issues a JWT on register/login (bcrypt-hashed
  passwords, `POST /auth/register`, `POST /auth/login`). `JwtAuthGuard`
  protects `/sync/push`, `/sync/pull`, and `/advisory/query`; the mediator id
  comes from the token, not the request body, so one account can't push or
  overwrite another's cases. The mobile app caches the token + profile
  on-device (`AuthSessionService`) so reopening the app never needs
  connectivity — only register/login/sign-out touch the network. Sign-out
  (`SyncStatusScreen._signOut`) refuses to proceed while cases are still
  pending, then clears the local case cache and session; the next sign-in
  calls `GET /sync/pull` to hydrate the local DB again.
- **Local-first storage**: Drift (SQLite) on-device. A case write never
  depends on the network; `synced_at` is only set once the backend confirms
  receipt (`backend/src/cases/cases.service.ts`).
- **Sync**: `mobile/lib/services/sync_service.dart` listens for connectivity
  changes and pushes pending cases; a manual "Sync now" does the same thing.
  Failures just leave cases pending for the next attempt — nothing is lost.
- **Advisory retrieval**: `backend/src/advisory/advisory.service.ts` embeds
  the query with Gemini, fetches every `document_chunks` row, and ranks them
  by cosine similarity computed in application code
  (`backend/src/advisory/similarity.ts`) rather than a DB-native vector
  search — the seeded corpus is small enough that scanning it in memory is
  simpler and works against any MongoDB instance (no Atlas Vector Search
  dependency). It only lets the model answer from excerpts above a similarity
  floor — otherwise it explicitly declines rather than hallucinating. Every
  claim in the summary is expected to cite `(Document Title, Section)`.
- **Database**: MongoDB via Prisma. `mediatorId` on `Case` is a plain field,
  not a Prisma `@relation` — Mongo has no joins/foreign keys to enforce
  anyway, so `CasesService.aggregateByTypeAndRegion` looks mediators up
  itself and groups in application code instead.
- **Referral flag**: keyword rules in `referral_categories.json` (mirrored in
  both `backend/src/referral/` and `mobile/assets/config/`) run on-device at
  save time so it works with zero connectivity. The same categories are passed
  to Gemini during an advisory lookup as a secondary, LLM-assisted check
  (`suggestsReferral` in the response) — this is the "keyword + LLM-assisted"
  classifier from the spec, and the category list is a plain JSON file you can
  hand-edit and explain in a demo, not opaque model behavior.
- **Voice notes**: `mobile/lib/services/audio_recorder_service.dart` records
  real WAV files on-device (separate from the `speech_to_text` dictation that
  fills the description). `AdvisoryApiClient.query` uploads them as
  multipart file parts alongside the description; the backend
  (`AdvisoryController` + `AdvisoryService.generateWithAudio`) passes each
  recording to Gemini as inline audio data in the same multimodal request as
  the text prompt, so the summary can reflect the actual recording, not just
  its transcript.

## Known simplifications / next steps (not built for this demo)

- **`kSkipAuthApiCalls` dev flag** — `mobile/lib/constants/dev_flags.dart` has
  a flag that, when `true`, makes Sign In/Register skip the real network call
  entirely (useful for working on the rest of the UI with no backend
  reachable). It's currently `false` (real auth). If you ever flip it back on
  for local UI work, remember to flip it back off before relying on real
  accounts again.
- **Voice notes don't sync across devices** — `voiceNoteRefs` are local file
  paths, valid only on the device that recorded them. Pulling a case on a
  different/reinstalled device brings back the reference but not the audio
  bytes; `CaseDetailScreen` only offers playback for paths that still exist
  locally. A real deployment would need to actually upload and store the
  audio files (e.g. object storage), not just reference a local path.
- **Auth is real but minimal** — bcrypt-hashed passwords and JWTs are genuine,
  but there's no password reset, refresh tokens, rate limiting on
  login/register, or account lockout. The JWT is cached in plain
  `shared_preferences` on-device, not secure/encrypted storage.
- **No encryption at rest or in transit for case data** — the mobile SQLite
  database is unencrypted and the demo backend runs over plain HTTP
  (`android:usesCleartextTraffic="true"` in the manifest, `app.enableCors()`
  wide open in `main.ts`). A real deployment needs TLS, encrypted local
  storage, and field-level encryption for case descriptions/parties given how
  sensitive this data is.
- **No real legal database ingestion pipeline** — `backend/seed_data/*.txt`
  are hand-written placeholder excerpts, not a real corpus or ingestion
  pipeline for statutes/case law.
- **Referral config duplication** — the category list is mirrored by hand in
  two places (`backend/src/referral/referral-categories.json` and
  `mobile/assets/config/referral_categories.json`); a real version would serve
  it from one place and have the app cache it (there's already a
  `GET /referral/categories` endpoint for this).
- **No multi-tenant admin dashboard** — `GET /stats/aggregate` returns
  anonymized case counts by type/region as a building block, but there's no
  UI for it.
- **Similarity search doesn't scale past a small corpus** — every
  `document_chunks` row is fetched and ranked in application code on every
  advisory query (see "Architecture notes"). Fine for a seeded demo corpus of
  a few dozen chunks; a real corpus of statutes/case law would need a proper
  vector index (e.g. Atlas Vector Search, or a dedicated vector DB).
- **The local dev Mongo replica set is single-node** (`mongo` +
  `mongo-init` in `docker-compose.yml`) — fine for local development, but not
  how you'd run Mongo for real durability/failover.
