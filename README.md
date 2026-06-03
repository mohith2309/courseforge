# CourseForge

**Tell the AI your goal — it builds the whole course for you.**

You type something like *"I'm studying for IAS, help me crack it"* and CourseForge
generates a complete, structured course on the spot — it decides the modules,
lessons, and quizzes you need — then drops you straight into learning it. The AI
is the course builder; you're always the student.

A single **Flutter** app (iOS / Android / Web). Offline-first, zero config to run.

---

## The core loop

1. **Build tab** → "What do you want to learn?" → type your goal (or tap an example).
2. The app generates a tailored course (modules → lessons → key points → a quiz per lesson).
3. You're auto-enrolled and land on the course, ready to learn.
4. Read lessons, take quizzes (instant feedback, 60% to pass), ask the AI doubts,
   track progress, earn a certificate at 100%.

The structure is decided **per goal** — a language goal and an exam goal produce
different module layouts. With a Gemini key it's fully tailored; without one it
still produces a usable structured draft so the whole flow works offline.

---

## What's built

| Feature | Status |
|---|---|
| **AI course generator** from a plain-language goal (Gemini 2.0 Flash) | ✅ |
| Generated courses persisted locally + auto-enrolled | ✅ |
| Learning interface: lesson reader, key points, notes, bookmarks, lesson nav | ✅ |
| Quiz: MCQs, instant feedback + explanations, 60% pass, unlimited retakes | ✅ |
| AI doubt solver (per-lesson, grounded in the lesson) | ✅ |
| Progress dashboard: streak, time, completion chart (fl_chart) | ✅ |
| Certificate on 100% completion, with QR verification | ✅ |
| Explore tab: sample courses (incl. a hand-written IAS course) + search | ✅ |
| Dark mode, offline persistence | ✅ |

### Architecture

- **State:** Riverpod (`lib/providers/providers.dart`)
- **Routing:** go_router with a 5-tab shell — Build · Explore · Learning · Progress · Settings (`lib/router.dart`)
- **AI:** `GeminiService.generateCourse(goal)` returns a full `Course`; falls back
  to a structured offline draft when no key is set. Same service powers the
  per-lesson doubt solver.
- **Course library:** `CourseLibraryNotifier` merges AI-generated courses
  (persisted in `GeneratedCoursesStore`) with the bundled sample courses, and
  updates live the moment a new course is generated.
- **Offline-first:** all progress (enrollments, completed lessons, quiz scores,
  notes, bookmarks, streak) persists locally via shared_preferences.

### Design

Professional exam-prep aesthetic (not playful): **teal** (trust/progress) +
**amber** (action). Defined once in `lib/theme/app_theme.dart`, light + dark,
8pt spacing rhythm, WCAG-AA contrast on key pairs.

---

## Run it

```bash
cd flutter_app
flutter pub get
flutter run            # on a connected Android/iOS device or emulator
```

Native mobile app (Android/iOS). Runs with **zero config** — AI keys are embedded
and payments use the **native Razorpay SDK** in-app (no web checkout). The Gemini
key is already wired; override with `--dart-define=GEMINI_API_KEY=your_key`.

### Try it
Open the **Build** tab → tap *"I'm studying for IAS, help me crack it"* → watch
it build the course → start the first lesson → take the quiz.

---

## Gamification (Duolingo-style)

- **XP & levels** — +15 per lesson, +30 per quiz pass (+20 for a perfect score); 100 XP per level.
- **Daily goal** — 50 XP/day with a progress bar on the home screen.
- **Streak** — consecutive active days.
- **Hearts** — 5/day, refill daily; spent on wrong *practice* answers (core learning is never gated); Pro = unlimited.
- **Badges** — First steps, Level 5, 3-day streak, Week warrior, Perfect quiz, Curator, Hour of focus, Graduate (on the Progress tab).

## Backend (`server/`)

Zero-dependency Node server (same style as GenPay's) that **keeps the AI keys off the device** and routes tasks to the best model:

| Endpoint | Purpose | Engine |
|---|---|---|
| `GET /health` | status | — |
| `POST /ai/generate-course` | build a course from a goal | Gemini (JSON) |
| `POST /ai/doubt` | answer a doubt with live internet | Gemini + Search |
| `POST /ai/practice` | fast practice quiz | NIM Llama 3.1 |
| `POST /auth/register` · `/auth/login` | accounts | scrypt |
| `POST /courses/publish` · `GET /courses/published` | publishing (70/30, approved only) | store |
| `POST /payments/create-order` · `/payments/verify` | Razorpay buy + 70% payout | Razorpay |
| `GET /admin/pending` · `POST /admin/review` · `/admin/verify-publisher` | review (x-admin-token) | store |

```bash
cd server
cp .env.example .env   # fill in keys (a working .env is already provided locally)
node server.js         # http://localhost:8788
```

### Datastore — file / Firestore / RTDB

Pluggable via `DATA_BACKEND`, all zero-dependency:
- `file` — `server/data/*.json` (dev).
- `firestore` — **Cloud Firestore over REST**, currently wired to the existing
  **dittox project (`dittoc-5a839`)**. The server signs in as a dedicated service
  user (`courseforge-backend@cf.local`) and stores each collection as a JSON-string
  doc under `users/{serviceUid}/cf_store/{name}` — which the project's security rules
  allow for the owning user, so **no console/rules changes were needed**.
- `firebase` — Firebase Realtime Database over REST.

Switch by editing `DATA_BACKEND` in `server/.env`; same `load`/`save` API, no code changes.

### Community marketplace, buying & admin (in-app)

- **Browse/buy** (Explore → *Community courses*, or Settings → Marketplace): lists approved
  community courses with the publisher's **verified badge**; **Buy** opens a Razorpay
  checkout sheet. The server creates a **real Razorpay order**; on confirmation the course
  lands in *My Learning* and the publisher is credited **70%**.
- **Admin** (Settings → Admin review): enter the `ADMIN_TOKEN`, then **approve/reject**
  pending submissions and **verify publishers**. Only approved courses appear in the marketplace.

> Razorpay runs in **test mode** with a working test key. The actual card/UPI entry UI
> (native `razorpay_flutter` / web `checkout.js`) is the one remaining seam — purchases
> currently confirm in test-simulated mode after a real order is created.

Deploy on **Railway** (`railway.json` included).

### Connect the app to the backend

```bash
# 1. start the server
cd server && node server.js          # :8788

# 2. run the app (device/emulator) pointed at it (keys now leave the device)
cd ../flutter_app
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8788   # Android emulator
#   physical device: use your machine's LAN IP, e.g. http://192.168.1.5:8788
```

With `BACKEND_URL` set, course generation, the doubt solver, and practice quizzes
all route through the server. Without it, the app runs fully on-device (embedded keys).

### Accounts & publishing (in-app)

- **Accounts are optional** — the app is fully usable signed out. Sign in (Settings → Account)
  only to publish.
- **Publish** (Settings → Publish a course): pick one of your AI-built courses, set a price,
  see your **70%** share, and submit. It lands in the backend as `pending_review`.

## Project layout

```
courseforge/
├── server/                # zero-dep Node backend (AI proxy, accounts, publishing)
└── flutter_app/
    ├── lib/
    │   ├── models/        # Course, Module, Lesson, Quiz, Question (+ toJson)
    │   ├── services/      # gemini (generateCourse + doubts), stores, payment
    │   ├── providers/     # Riverpod: course library + generation
    │   ├── screens/       # ai_builder, learning, quiz, doubt, progress, certificate, explore, settings
    │   ├── widgets/       # shared UI
    │   ├── theme/         # design system
    │   ├── router.dart
    │   └── main.dart
    └── assets/data/       # sample courses (ias_course.json, catalog.json)
```

> Note: an earlier draft included a React "creator dashboard" — removed. There
> are no creators in this product; the AI generates the courses.
