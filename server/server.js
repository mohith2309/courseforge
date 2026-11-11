// CourseForge backend — zero-dependency Node server (hardened).
//
// Security layers: per-IP rate limiting, request-body size cap, CORS allowlist,
// signed bearer tokens (enforced on publish/payments), APP_KEY-gated AI proxy,
// real Razorpay signature verification, strong admin token, generic errors.
//
// Run: node server.js  ·  Deploy: Railway (railway.json)

const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// ── .env loader ──────────────────────────────────────────────────────────────
const ENV = {};
try {
  const raw = fs.readFileSync(path.join(__dirname, '.env'), 'utf8');
  for (const line of raw.split('\n')) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m) ENV[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
} catch {/* rely on process.env */}
const cfg = (k, d = '') => process.env[k] || ENV[k] || d;

const PORT = cfg('PORT', '8788');
const PROD = cfg('NODE_ENV') === 'production';
const GEMINI_KEY = cfg('GEMINI_API_KEY');
const GEMINI_MODEL = cfg('GEMINI_MODEL', 'gemini-2.5-flash');
const NIM_KEY = cfg('NVIDIA_API_KEY');
const NIM_BASE = cfg('NVIDIA_API_BASE', 'https://integrate.api.nvidia.com/v1');
const NIM_MODEL = cfg('NVIDIA_MODEL', 'meta/llama-3.1-8b-instruct');
const LESSON_MODEL = cfg('NVIDIA_LESSON_MODEL', 'meta/llama-3.3-70b-instruct');
const GROQ_KEY = cfg('GROQ_API_KEY');
const GROQ_MODEL = cfg('GROQ_MODEL', 'llama-3.3-70b-versatile');
const GROQ_LIVE = Boolean(GROQ_KEY);
const GH_TOKEN = cfg('GITHUB_MODELS_TOKEN');
const GH_MODEL = cfg('GITHUB_MODELS_MODEL', 'openai/gpt-4.1-mini');
const GH_LIVE = Boolean(GH_TOKEN);
const MISTRAL_KEY = cfg('MISTRAL_API_KEY');
const MISTRAL_MODEL = cfg('MISTRAL_MODEL', 'mistral-large-latest');
const MISTRAL_LIVE = Boolean(MISTRAL_KEY);
const RZP_KEY_ID = cfg('RAZORPAY_KEY_ID');
const RZP_KEY_SECRET = cfg('RAZORPAY_KEY_SECRET');
const RZP_LIVE = Boolean(RZP_KEY_ID && RZP_KEY_SECRET);
const ALLOW_MOCK_PAYMENTS = cfg('ALLOW_MOCK_PAYMENTS', 'false') === 'true';
const ADMIN_TOKEN = cfg('ADMIN_TOKEN', 'admin-dev');
const JWT_SECRET = cfg('JWT_SECRET', 'dev-secret');
const APP_KEY = cfg('APP_KEY'); // gate for AI endpoints
const FIREBASE_PROJECT_NUM = cfg('FIREBASE_PROJECT_NUM', '374206849691');
const ALLOWED_ORIGINS = cfg('ALLOWED_ORIGINS', '')
  .split(',').map((s) => s.trim()).filter(Boolean);
const COMMISSION = 0.3;
// Platform owner's user id — courses they publish keep 100% (no creator split).
const PLATFORM_OWNER_ID = cfg('PLATFORM_OWNER_ID', '');
const MAX_BODY = 512 * 1024; // 512 KB

// ── HTTPS JSON helper ────────────────────────────────────────────────────────
function httpsJson(url, { method = 'POST', headers = {}, body, timeoutMs = 45000 } = {}) {
  return new Promise((resolve, reject) => {
    const data = body !== undefined && body !== null ? JSON.stringify(body) : null;
    const req = https.request(new URL(url), {
      method,
      // Force IPv4: many hosts (Railway) have broken/disabled outbound IPv6, where
      // an IPv6 attempt hangs until timeout. This was causing intermittent stalls
      // across ALL providers at once. IPv4 is reliable everywhere these APIs live.
      family: 4,
      headers: {
        'Content-Type': 'application/json',
        ...(data ? { 'Content-Length': Buffer.byteLength(data) } : {}),
        ...headers,
      },
    }, (res) => {
      let buf = '';
      res.on('data', (c) => (buf += c));
      res.on('end', () => {
        try { resolve({ status: res.statusCode, body: buf ? JSON.parse(buf) : null }); }
        catch { resolve({ status: res.statusCode, body: buf }); }
      });
    });
    req.on('error', reject);
    // Hard timeout: never let a hung upstream (Gemini/NIM) block the request forever.
    req.setTimeout(timeoutMs, () => req.destroy(new Error('upstream timeout')));
    if (data) req.write(data);
    req.end();
  });
}

// ── Datastore: file | firestore | firebase(RTDB) ─────────────────────────────
const DATA_BACKEND = cfg('DATA_BACKEND', 'file');
const DATA_DIR = path.join(__dirname, 'data');
const FS_PROJECT = cfg('FIREBASE_PROJECT_ID');
const FS_KEY = cfg('FIREBASE_API_KEY');
const FS_EMAIL = cfg('FIREBASE_BACKEND_EMAIL');
const FS_PASS = cfg('FIREBASE_BACKEND_PASSWORD');
const USE_FIRESTORE = DATA_BACKEND === 'firestore' && FS_PROJECT && FS_KEY && FS_EMAIL && FS_PASS;
const FS_DOCS = `https://firestore.googleapis.com/v1/projects/${FS_PROJECT}/databases/(default)/documents`;
let _fsToken = null, _fsUid = null, _fsExp = 0;
async function fsAuth(force = false) {
  if (!force && _fsToken && Date.now() < _fsExp) return;
  const idtk = 'https://identitytoolkit.googleapis.com/v1';
  const cred = { email: FS_EMAIL, password: FS_PASS, returnSecureToken: true };
  let r = await httpsJson(`${idtk}/accounts:signInWithPassword?key=${FS_KEY}`, { body: cred });
  if (r.status !== 200) r = await httpsJson(`${idtk}/accounts:signUp?key=${FS_KEY}`, { body: cred });
  if (r.status !== 200) throw new Error('firebase auth failed');
  _fsToken = r.body.idToken; _fsUid = r.body.localId; _fsExp = Date.now() + 3300 * 1000;
}
const _fsUrl = (name) => `${FS_DOCS}/users/${_fsUid}/cf_store/${name}?key=${FS_KEY}`;
async function fsLoad(name) {
  await fsAuth();
  let r = await httpsJson(_fsUrl(name), { method: 'GET', headers: { Authorization: `Bearer ${_fsToken}` } });
  if (r.status === 401) { await fsAuth(true); r = await httpsJson(_fsUrl(name), { method: 'GET', headers: { Authorization: `Bearer ${_fsToken}` } }); }
  if (r.status === 200 && r.body?.fields?.json) { try { return JSON.parse(r.body.fields.json.stringValue); } catch { return []; } }
  return [];
}
async function fsSave(name, value) {
  await fsAuth();
  const body = { fields: { json: { stringValue: JSON.stringify(value) } } };
  let r = await httpsJson(_fsUrl(name), { method: 'PATCH', headers: { Authorization: `Bearer ${_fsToken}` }, body });
  if (r.status === 401) { await fsAuth(true); r = await httpsJson(_fsUrl(name), { method: 'PATCH', headers: { Authorization: `Bearer ${_fsToken}` }, body }); }
  if (r.status !== 200) throw new Error('firestore save failed');
}
const FB_URL = cfg('FIREBASE_DB_URL', '').replace(/\/$/, '');
const FB_SECRET = cfg('FIREBASE_DB_SECRET', '');
const USE_RTDB = DATA_BACKEND === 'firebase' && Boolean(FB_URL);
async function load(name) {
  if (USE_FIRESTORE) return fsLoad(name);
  if (USE_RTDB) {
    const auth = FB_SECRET ? `?auth=${FB_SECRET}` : '';
    const { status, body } = await httpsJson(`${FB_URL}/${name}.json${auth}`, { method: 'GET' });
    if (status === 200 && body) return Array.isArray(body) ? body : Object.values(body);
    return [];
  }
  try { return JSON.parse(fs.readFileSync(path.join(DATA_DIR, `${name}.json`), 'utf8')); } catch { return []; }
}
async function save(name, value) {
  if (USE_FIRESTORE) return fsSave(name, value);
  if (USE_RTDB) {
    const auth = FB_SECRET ? `?auth=${FB_SECRET}` : '';
    await httpsJson(`${FB_URL}/${name}.json${auth}`, { method: 'PUT', body: value });
    return;
  }
  fs.mkdirSync(DATA_DIR, { recursive: true });
  fs.writeFileSync(path.join(DATA_DIR, `${name}.json`), JSON.stringify(value, null, 2));
}

// ── AI providers ─────────────────────────────────────────────────────────────
async function gemini(prompt, { json = false, grounding = false, maxTokens = 24000, retries = 3, timeoutMs = 50000 } = {}) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_KEY}`;
  const reqBody = { contents: [{ parts: [{ text: prompt }] }] };
  reqBody.generationConfig = { thinkingConfig: { thinkingBudget: 0 }, maxOutputTokens: maxTokens };
  if (json) reqBody.generationConfig.responseMimeType = 'application/json';
  if (grounding) reqBody.tools = [{ google_search: {} }];
  let lastErr;
  for (let a = 0; a < retries; a++) {
    try {
      const { status, body } = await httpsJson(url, { body: reqBody, timeoutMs });
      if (status === 200) { const t = body?.candidates?.[0]?.content?.parts?.[0]?.text; if (t) return t; throw new Error('empty'); }
      lastErr = new Error(`Gemini ${status}`); if (status < 500) break;
    } catch (e) { lastErr = e; }
    if (a < retries - 1) await new Promise((r) => setTimeout(r, 1500 * (a + 1)));
  }
  throw lastErr;
}
async function nim(prompt, { maxTokens = 900, temperature = 0.4, model = NIM_MODEL, json = false, timeoutMs = 45000 } = {}) {
  const reqBody = { model, messages: [{ role: 'user', content: prompt }], max_tokens: maxTokens, temperature };
  if (json) reqBody.response_format = { type: 'json_object' };
  const { status, body } = await httpsJson(`${NIM_BASE}/chat/completions`, { headers: { Authorization: `Bearer ${NIM_KEY}` }, body: reqBody, timeoutMs });
  if (status !== 200) throw new Error(`NIM ${status}`);
  return body.choices[0].message.content;
}
async function groq(prompt, { maxTokens = 4000, temperature = 0.6, json = false, timeoutMs = 15000 } = {}) {
  const reqBody = { model: GROQ_MODEL, messages: [{ role: 'user', content: prompt }], max_tokens: maxTokens, temperature };
  if (json) reqBody.response_format = { type: 'json_object' };
  const { status, body } = await httpsJson('https://api.groq.com/openai/v1/chat/completions', { headers: { Authorization: `Bearer ${GROQ_KEY}` }, body: reqBody, timeoutMs });
  if (status !== 200) throw new Error(`Groq ${status}`);
  return body.choices[0].message.content;
}
// GitHub Models (OpenAI-compatible). High quality (gpt-4.1-mini) but low daily
// limits — used as a fallback, not the primary.
async function ghModels(prompt, { maxTokens = 2400, temperature = 0.6, json = false, timeoutMs = 18000 } = {}) {
  const reqBody = { model: GH_MODEL, messages: [{ role: 'user', content: prompt }], max_tokens: maxTokens, temperature };
  if (json) reqBody.response_format = { type: 'json_object' };
  const { status, body } = await httpsJson('https://models.github.ai/inference/chat/completions', { headers: { Authorization: `Bearer ${GH_TOKEN}` }, body: reqBody, timeoutMs });
  if (status !== 200) throw new Error(`GitHubModels ${status}`);
  return body.choices[0].message.content;
}
// Mistral AI (OpenAI-compatible). High quality, reliable, good free limits.
async function mistral(prompt, { maxTokens = 2400, temperature = 0.5, json = false, model = MISTRAL_MODEL, timeoutMs = 16000 } = {}) {
  const reqBody = { model, messages: [{ role: 'user', content: prompt }], max_tokens: maxTokens, temperature };
  if (json) reqBody.response_format = { type: 'json_object' };
  const { status, body } = await httpsJson('https://api.mistral.ai/v1/chat/completions', { headers: { Authorization: `Bearer ${MISTRAL_KEY}` }, body: reqBody, timeoutMs });
  if (status !== 200) throw new Error(`Mistral ${status}`);
  return body.choices[0].message.content;
}

// Plain-text generation with provider failover (doubt solver, practice, etc.).
// Tries the fast/reliable providers in order; throws only if ALL fail. Gemini is
// excluded (its key is dead) — this is why answers used to fall back to canned text.
async function aiText(prompt, { maxTokens = 1200, temperature = 0.6 } = {}) {
  const chain = [];
  if (GROQ_LIVE) chain.push(() => groq(prompt, { maxTokens, temperature, timeoutMs: 16000 }));
  if (MISTRAL_LIVE) chain.push(() => mistral(prompt, { maxTokens, temperature, model: 'mistral-small-latest', timeoutMs: 20000 }));
  chain.push(() => nim(prompt, { maxTokens, temperature, timeoutMs: 22000 }));
  if (GH_LIVE) chain.push(() => ghModels(prompt, { maxTokens, temperature, timeoutMs: 22000 }));
  let lastErr;
  for (const fn of chain) {
    try { const t = await fn(); if (t && t.trim()) return t.trim(); } catch (e) { lastErr = e; }
  }
  throw lastErr || new Error('all providers failed');
}
function coursePrompt(goal) {
  return `You are a world-class curriculum designer and expert tutor. A learner says: "${goal}".
Design a thorough, in-depth self-study course that takes them from beginner to genuinely competent. Return ONLY JSON:
{"title":"","subtitle":"","description":"a rich 3-4 sentence overview","category":"","tags":[],"thumbnailEmoji":"",
"modules":[{"title":"","description":"2-3 sentence module overview","lessons":[{"title":"","summary":"1-2 sentence summary",
"script":"a detailed 350-500 word mini-lesson with a concrete worked example","keyPoints":["5-6 substantial bullets"],"durationMinutes":12,
"quiz":{"questions":[{"stem":"","options":["","","",""],"correctIndex":0,"explanation":"why, 1-2 sentences"}]}}]}]}
Make 6-8 modules, each with 3-4 lessons, 3 quiz questions per lesson. Be comprehensive — cover fundamentals, intermediate, and advanced topics so nothing important is missing. Accurate, specific, and example-driven. Vary the correct-answer position; never hint the answer in the stem/options.`;
}
function lessonPrompt(courseTitle, moduleTitle, lessonTitle, summary) {
  return `You are a patient, masterful tutor writing ONE complete, in-depth lesson — like a chapter from an excellent textbook combined with a great teacher's spoken explanation.
Course: ${courseTitle}
Module: ${moduleTitle}
Lesson: ${lessonTitle}
${summary ? `Focus: ${summary}\n` : ''}
Return ONLY JSON: {"script":"","keyPoints":["..."],"quiz":{"questions":[{"stem":"","options":["","","",""],"correctIndex":0,"explanation":""}]}}
The "script" MUST be VERY detailed — 1100 to 1600 words of flowing, conversational prose across 8-11 substantial paragraphs that truly TEACH: (1) an engaging hook and why this matters, (2) a clear plain-language definition of every key term, (3) a relatable everyday analogy, (4) a fully worked example with every step shown and explained, (5) the deeper "why it works" mechanism, (6) a second, contrasting example or edge case, (7) how it connects to the bigger picture / real-world uses, (8) common mistakes and misconceptions with how to avoid each, (9) a concise recap of the key takeaways. Write naturally as if speaking to one student — NO markdown headings, NO bullet lists inside the script, just rich paragraphs. Do not be brief; err on the side of MORE depth and detail. keyPoints: 7-9 substantial bullets. quiz: exactly 3 questions, 4 options each, one correct, each with a 1-2 sentence explanation. CRITICAL for the quiz: never reveal the correct option to the learner — no "(correct)", "Answer:", asterisks or hints in the stem/options; the script and keyPoints must NOT state the quiz answers; vary which position (0-3) holds the correct option; put the reasoning ONLY in each question's "explanation".`;
}
function parseLooseJson(text) {
  const s = text.indexOf('{'), e = text.lastIndexOf('}');
  if (s < 0 || e <= s) throw new Error('no JSON');
  return JSON.parse(text.slice(s, e + 1).replace(/[\u0000-\u001F]+/g, ' '));
}

// ── Security primitives ──────────────────────────────────────────────────────
const b64url = (b) => Buffer.from(b).toString('base64url');
function hmac(s) { return crypto.createHmac('sha256', JWT_SECRET).update(s).digest('base64url'); }
function signToken(uid) {
  const payload = b64url(JSON.stringify({ uid, exp: Date.now() + 30 * 864e5 }));
  return `${payload}.${hmac(payload)}`;
}
function verifyToken(tok) {
  if (!tok || tok.indexOf('.') < 0) return null;
  const [payload, sig] = tok.split('.');
  const expected = hmac(payload);
  const bSig = Buffer.from(sig), bExp = Buffer.from(expected);
  if (bSig.byteLength !== bExp.byteLength || !crypto.timingSafeEqual(bSig, bExp)) return null;
  try { const p = JSON.parse(Buffer.from(payload, 'base64url').toString()); return p.exp > Date.now() ? p.uid : null; }
  catch { return null; }
}
function bearer(req) {
  const h = req.headers['authorization'] || '';
  return h.startsWith('Bearer ') ? verifyToken(h.slice(7)) : null;
}
function safeEq(a, b) {
  const bA = Buffer.from(a || ''), bB = Buffer.from(b || '');
  if (bA.byteLength === 0 || bA.byteLength !== bB.byteLength) return false;
  return crypto.timingSafeEqual(bA, bB);
}
const isAdmin = (req) =>
  safeEq(req.headers['x-admin-token'] || '', ADMIN_TOKEN);

// Per-IP sliding-window rate limiter (in-memory).
const buckets = new Map();
function clientIp(req) {
  return (req.headers['x-forwarded-for'] || '').split(',')[0].trim() || req.socket.remoteAddress || 'unknown';
}
function rateLimit(key, limit, windowMs) {
  const now = Date.now();
  const arr = (buckets.get(key) || []).filter((t) => now - t < windowMs);
  if (arr.length >= limit) { buckets.set(key, arr); return false; }
  arr.push(now); buckets.set(key, arr);
  return true;
}
setInterval(() => { // prune
  const now = Date.now();
  for (const [k, arr] of buckets) { const f = arr.filter((t) => now - t < 60000); if (f.length) buckets.set(k, f); else buckets.delete(k); }
}, 120000).unref?.();

async function rzpCreateOrder(amountPaise, receipt, transfers) {
  const auth = 'Basic ' + Buffer.from(`${RZP_KEY_ID}:${RZP_KEY_SECRET}`).toString('base64');
  const orderBody = { amount: amountPaise, currency: 'INR', receipt, payment_capture: 1 };
  // Razorpay Route: split a slice of the payment to a creator's linked account
  // (the rest stays with the platform automatically).
  if (transfers && transfers.length) orderBody.transfers = transfers;
  const { status, body } = await httpsJson('https://api.razorpay.com/v1/orders', {
    headers: { Authorization: auth }, body: orderBody,
  });
  if (status !== 200) throw new Error(`Razorpay ${status}`);
  return body;
}
function rzpVerify(orderId, paymentId, signature) {
  const expected = crypto.createHmac('sha256', RZP_KEY_SECRET).update(`${orderId}|${paymentId}`).digest('hex');
  return safeEq(expected, signature || '');
}
function hashPw(pw, salt) { return crypto.scryptSync(pw, salt, 32).toString('hex'); }
function enrich(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}
// Whitelist course fields on publish (prevents rating/enrollment spoofing).
function cleanCourse(c) {
  return {
    id: String(c.id || crypto.randomUUID()).slice(0, 64),
    title: String(c.title || '').slice(0, 200),
    subtitle: String(c.subtitle || '').slice(0, 300),
    description: String(c.description || '').slice(0, 4000),
    category: String(c.category || 'General').slice(0, 40),
    tags: Array.isArray(c.tags) ? c.tags.slice(0, 8).map((t) => String(t).slice(0, 30)) : [],
    thumbnailEmoji: String(c.thumbnailEmoji || '📘').slice(0, 8),
    aiGenerated: Boolean(c.aiGenerated),
    modules: Array.isArray(c.modules) ? c.modules : [],
  };
}

// ── HTTP plumbing ────────────────────────────────────────────────────────────
function corsFor(req) {
  const o = req.headers.origin;
  const h = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-admin-token, x-app-key',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
  };
  if (o && ALLOWED_ORIGINS.includes(o)) h['Access-Control-Allow-Origin'] = o;
  return h;
}
function send(res, req, code, obj) { res.writeHead(code, corsFor(req)); res.end(JSON.stringify(obj)); }
function readBody(req) {
  return new Promise((resolve) => {
    let b = '', size = 0, done = false;
    const finish = (v) => { if (!done) { done = true; resolve(v); } };
    req.on('data', (c) => {
      if (done) return;            // stop buffering once we've decided (memory-safe)
      size += c.length;
      if (size > MAX_BODY) { finish({ __big: true }); return; } // reply cleanly, don't reset socket
      b += c;
    });
    req.on('end', () => { try { finish(b ? JSON.parse(b) : {}); } catch { finish({}); } });
    req.on('error', () => finish({}));
  });
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') return send(res, req, 204, {});
  const url = new URL(req.url, 'http://localhost');
  const p = url.pathname, m = req.method, ip = clientIp(req);

  // Global rate limit.
  if (!rateLimit(`g:${ip}`, 150, 60000)) return send(res, req, 429, { error: 'Too many requests' });

  try {
    if (m === 'GET' && p === '/health') {
      return send(res, req, 200, {
        ok: true, gemini: Boolean(GEMINI_KEY), nim: Boolean(NIM_KEY), groq: GROQ_LIVE, mistral: MISTRAL_LIVE, github: GH_LIVE,
        razorpay: RZP_LIVE, store: USE_FIRESTORE ? 'firestore' : USE_RTDB ? 'firebase-rtdb' : 'file',
        secure: true,
      });
    }

    // ── AI (APP_KEY gate + tight rate limit) ──
    if (p.startsWith('/ai/')) {
      if (!APP_KEY || !safeEq(req.headers['x-app-key'] || '', APP_KEY))
        return send(res, req, 401, { error: 'app key required' });
      // Diagnostic: probe each provider from inside the server (not rate-limited).
      if (p === '/ai/diag') {
        const pr = lessonPrompt('IAS', 'Polity', 'Fundamental Rights', 'Articles 12-35'); // real workload
        const probe = (fn) => { const s = Date.now(); return fn().then((r) => ({ ok: true, ms: Date.now() - s, len: String(r).length })).catch((e) => ({ ok: false, ms: Date.now() - s, err: String((e && e.message) || e).slice(0, 70) })); };
        const out = {};
        out.groq = GROQ_LIVE ? await probe(() => groq(pr, { json: true, maxTokens: 2400, timeoutMs: 20000 })) : 'off';
        out.mistral = MISTRAL_LIVE ? await probe(() => mistral(pr, { json: true, maxTokens: 2400, timeoutMs: 20000 })) : 'off';
        out.nim = await probe(() => nim(pr, { json: true, maxTokens: 1800, timeoutMs: 20000 }));
        out.github = GH_LIVE ? await probe(() => ghModels(pr, { json: true, maxTokens: 2400, timeoutMs: 20000 })) : 'off';
        return send(res, req, 200, out);
      }
      if (!rateLimit(`ai:${ip}`, 30, 60000)) return send(res, req, 429, { error: 'AI rate limit — slow down' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });

      if (p === '/ai/generate-course') {
        const goal = String(body.goal || '').slice(0, 2000);
        if (!goal) return send(res, req, 400, { error: 'goal required' });
        // Groq 70B → Mistral large → GitHub gpt-4.1-mini → NVIDIA. (Gemini omitted: 0 quota.)
        // High token budget for a comprehensive 6-8 module course.
        if (GROQ_LIVE) { try { return send(res, req, 200, parseLooseJson(await groq(coursePrompt(goal), { json: true, maxTokens: 10000, timeoutMs: 45000 }))); } catch {} }
        if (MISTRAL_LIVE) { try { return send(res, req, 200, parseLooseJson(await mistral(coursePrompt(goal), { json: true, maxTokens: 14000, timeoutMs: 55000 }))); } catch {} }
        if (GH_LIVE) { try { return send(res, req, 200, parseLooseJson(await ghModels(coursePrompt(goal), { json: true, maxTokens: 14000, timeoutMs: 50000 }))); } catch {} }
        const nimCoursePrompt = `Create a thorough study course for: "${goal}". Return ONLY JSON {"title":"","subtitle":"","description":"3-4 sentences","category":"General","tags":[],"thumbnailEmoji":"📘","modules":[{"title":"","description":"2 sentences","lessons":[{"title":"","summary":"","script":"250-350 word lesson with an example","keyPoints":["4-5 bullets"],"durationMinutes":10,"quiz":{"questions":[{"stem":"","options":["","","",""],"correctIndex":0,"explanation":""}]}}]}]}. Make 5 modules, 3 lessons each, 3 questions each. Vary the correct-answer position; never hint the answer.`;
        try { return send(res, req, 200, parseLooseJson(await nim(nimCoursePrompt, { model: LESSON_MODEL, maxTokens: 12000, temperature: 0.5, json: true, timeoutMs: 60000 }))); } catch {}
        try { return send(res, req, 200, parseLooseJson(await nim(nimCoursePrompt, { maxTokens: 8000, temperature: 0.5, json: true, timeoutMs: 45000 }))); } catch {}
        return send(res, req, 503, { error: 'AI busy — try again' });
      }
      if (p === '/ai/lesson') {
        const pr = lessonPrompt(String(body.courseTitle || '').slice(0, 200), String(body.moduleTitle || '').slice(0, 200), String(body.lessonTitle || '').slice(0, 200), String(body.summary || '').slice(0, 500));
        // maxTokens 4096 for a VERY detailed 1100-1600 word lesson. Chain:
        // Groq 70B (best) → Mistral-small (separate quota) → GitHub gpt-4.1-mini.
        // Timeouts widened for the longer generation.
        if (GROQ_LIVE) { try { return send(res, req, 200, parseLooseJson(await groq(pr, { json: true, maxTokens: 4096, timeoutMs: 24000 }))); } catch {} }
        if (MISTRAL_LIVE) { try { return send(res, req, 200, parseLooseJson(await mistral(pr, { json: true, maxTokens: 4096, model: 'mistral-small-latest', timeoutMs: 30000 }))); } catch {} }
        if (GH_LIVE) { try { return send(res, req, 200, parseLooseJson(await ghModels(pr, { json: true, maxTokens: 4096, timeoutMs: 30000 }))); } catch {} }
        return send(res, req, 503, { error: 'could not generate lesson' });
      }
      if (p === '/ai/doubt') {
        const prompt = `You are an expert, patient tutor helping a student who is studying this lesson.
Lesson: ${String(body.lessonTitle || '').slice(0, 200)}
Lesson material:
${String(body.lessonText || '').slice(0, 8000)}

The student asks: "${String(body.question || '').slice(0, 1000)}"

Give a thorough, genuinely helpful answer (about 250-400 words): directly answer the question, explain the reasoning step by step, give a concrete example, and clear up any likely confusion. Write in warm, plain language as flowing prose (no markdown headings).`;
        try {
          const text = await aiText(prompt, { maxTokens: 1400, temperature: 0.6 });
          return send(res, req, 200, { text });
        } catch { return send(res, req, 503, { error: 'AI busy — try again' }); }
      }
      if (p === '/ai/practice') {
        const prompt = `Create ${Math.min(10, Number(body.count) || 5)} ${String(body.difficulty || 'medium')} multiple-choice questions as a JSON array ONLY (no prose):\n[{"stem":"","options":["","","",""],"correctIndex":0,"explanation":"why, 1-2 sentences"}]\n\nLesson: ${String(body.lessonTitle || '').slice(0, 200)}\n${String(body.lessonText || '').slice(0, 8000)}\n\nVary which position holds the correct option; never hint the answer in the stem or options.`;
        try {
          const raw = await aiText(prompt, { maxTokens: 1600, temperature: 0.5 });
          const s = raw.indexOf('['), e = raw.lastIndexOf(']');
          return send(res, req, 200, { questions: s >= 0 ? JSON.parse(raw.slice(s, e + 1).replace(/[ -]+/g, ' ')) : [] });
        } catch { return send(res, req, 200, { questions: [] }); }
      }
      return send(res, req, 404, { error: 'not found' });
    }

    // ── Accounts ──
    if (p.startsWith('/auth/')) {
      if (!rateLimit(`auth:${ip}`, 10, 60000)) return send(res, req, 429, { error: 'Too many attempts' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });

      if (m === 'POST' && p === '/auth/register') {
        const email = String(body.email || '').toLowerCase().slice(0, 200);
        const password = String(body.password || '');
        if (!email || password.length < 6) return send(res, req, 400, { error: 'valid email + 6+ char password required' });
        const users = await load('users');
        if (users.find((u) => u.email === email)) return send(res, req, 409, { error: 'account exists' });
        const salt = crypto.randomBytes(8).toString('hex');
        const user = { id: crypto.randomUUID(), email, name: String(body.name || email.split('@')[0]).slice(0, 60), salt, pw: hashPw(password, salt), verifiedPublisher: false, createdAt: Date.now() };
        users.push(user); await save('users', users);
        return send(res, req, 200, { token: signToken(user.id), userId: user.id, name: user.name, verifiedPublisher: false });
      }
      if (m === 'POST' && p === '/auth/login') {
        const email = String(body.email || '').toLowerCase();
        const user = (await load('users')).find((u) => u.email === email);
        if (!user || !safeEq(user.pw, hashPw(String(body.password || ''), user.salt)))
          return send(res, req, 401, { error: 'invalid credentials' });
        return send(res, req, 200, { token: signToken(user.id), userId: user.id, name: user.name, verifiedPublisher: Boolean(user.verifiedPublisher) });
      }
      // Exchange a verified Google/Firebase ID token for a server token.
      if (m === 'POST' && p === '/auth/exchange') {
        const idToken = String(body.idToken || '');
        if (!idToken) return send(res, req, 400, { error: 'idToken required' });
        const { status, body: info } = await httpsJson(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`, { method: 'GET' });
        if (status !== 200 || !info?.sub) return send(res, req, 401, { error: 'invalid Google token' });
        const audOk = String(info.aud || '').includes(FIREBASE_PROJECT_NUM) || String(info.azp || '').includes(FIREBASE_PROJECT_NUM);
        if (!audOk) return send(res, req, 401, { error: 'token audience mismatch' });
        const users = await load('users');
        let user = users.find((u) => u.id === info.sub);
        if (!user) { user = { id: info.sub, email: String(info.email || '').toLowerCase(), name: String(info.name || info.email || 'User').slice(0, 60), verifiedPublisher: false, google: true, createdAt: Date.now() }; users.push(user); await save('users', users); }
        return send(res, req, 200, { token: signToken(user.id), userId: user.id, name: user.name, verifiedPublisher: Boolean(user.verifiedPublisher) });
      }
      return send(res, req, 404, { error: 'not found' });
    }

    // ── Public catalog (read-only) ──
    if (m === 'GET' && p === '/courses/published') {
      const [published, users] = [await load('published'), await load('users')];
      return send(res, req, 200, { courses: published.filter((c) => c.status === 'published').map((c) => enrich(c, users)) });
    }

    // ── Publishing (auth required; publisherId from token) ──
    if (m === 'POST' && p === '/courses/publish') {
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });
      if (!body.course) return send(res, req, 400, { error: 'course required' });
      const priceInr = Math.max(0, Math.min(9999, Number(body.priceInr) || 0));
      const published = await load('published');
      const entry = { ...cleanCourse(body.course), priceInr, publisherId: uid, commissionRate: COMMISSION, publisherShare: Math.round(priceInr * (1 - COMMISSION)), enrollmentsCount: 0, status: 'pending_review', publishedAt: Date.now() };
      published.unshift(entry); await save('published', published);
      return send(res, req, 200, { ok: true, entry });
    }

    // ── Creator payout account (auth) — link a Razorpay account for Route ──
    if (m === 'POST' && p === '/publisher/payout-account') {
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });
      const acct = String(body.accountId || '').trim();
      if (!/^acc_[A-Za-z0-9]+$/.test(acct)) return send(res, req, 400, { error: 'expected a Razorpay account id like acc_XXXXXXXX' });
      const users = await load('users');
      const u = users.find((x) => x.id === uid);
      if (!u) return send(res, req, 404, { error: 'user not found' });
      u.razorpayAccountId = acct;
      await save('users', users);
      return send(res, req, 200, { ok: true });
    }
    if (m === 'GET' && p === '/publisher/payout-account') {
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const u = (await load('users')).find((x) => x.id === uid);
      return send(res, req, 200, { accountId: u ? (u.razorpayAccountId || '') : '' });
    }

    // ── Entitlements (auth) — server is the source of truth for what a user
    //    owns + Pro. Stops local-state tampering from unlocking content. ──
    if (m === 'GET' && p === '/me/entitlements') {
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const [purchases, users] = [await load('purchases'), await load('users')];
      const owned = [...new Set(purchases.filter((x) => x.buyerId === uid).map((x) => x.courseId))];
      const u = users.find((x) => x.id === uid);
      return send(res, req, 200, { pro: Boolean(u && u.pro), owned });
    }
    if (m === 'POST' && p === '/me/pro') {
      if (!ALLOW_MOCK_PAYMENTS) return send(res, req, 403, { error: 'mock payments disabled' });
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const users = await load('users');
      const u = users.find((x) => x.id === uid);
      if (!u) return send(res, req, 404, { error: 'user not found' });
      u.pro = true; await save('users', users);
      return send(res, req, 200, { ok: true });
    }
    // Guest → sign-in migration: attach courses bought / Pro unlocked while
    // signed out to the now-signed-in account.
    if (m === 'POST' && p === '/me/claim') {
      if (!ALLOW_MOCK_PAYMENTS) return send(res, req, 403, { error: 'mock payments disabled' });
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });
      const ids = Array.isArray(body.courseIds) ? body.courseIds.map(String).slice(0, 200) : [];
      const purchases = await load('purchases');
      const have = new Set(purchases.filter((x) => x.buyerId === uid).map((x) => x.courseId));
      let added = 0;
      for (const cid of ids) {
        if (!have.has(cid)) { purchases.unshift({ id: crypto.randomUUID(), courseId: cid, buyerId: uid, claimed: true, at: Date.now() }); have.add(cid); added++; }
      }
      if (added) await save('purchases', purchases);
      if (body.pro === true) {
        const users = await load('users');
        const u = users.find((x) => x.id === uid);
        if (u) { u.pro = true; await save('users', users); }
      }
      const owned = [...have];
      const u2 = (await load('users')).find((x) => x.id === uid);
      return send(res, req, 200, { ok: true, owned, pro: Boolean(u2 && u2.pro) });
    }

    // ── Payments ──
    if (p.startsWith('/payments/')) {
      if (!rateLimit(`pay:${ip}`, 20, 60000)) return send(res, req, 429, { error: 'Too many requests' });
      const uid = bearer(req);
      if (!uid) return send(res, req, 401, { error: 'sign in required' });
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });

      if (m === 'POST' && p === '/payments/create-order') {
        const course = (await load('published')).find((c) => c.id === body.courseId && c.status === 'published');
        if (!course) return send(res, req, 404, { error: 'course not found' });
        const paise = Math.max(100, course.priceInr * 100); // server-side price (no client tampering)
        // Route split: auto-pay the creator's share to their linked Razorpay
        // account. If they haven't linked one, no transfer — their share is
        // still recorded in the earnings ledger on /verify for manual payout.
        let transfers;
        const users = await load('users');
        const publisher = users.find((u) => u.id === course.publisherId);
        if (publisher && publisher.razorpayAccountId && publisher.id !== PLATFORM_OWNER_ID) {
          const sharePaise = Math.max(100, Math.round((course.publisherShare || Math.round(course.priceInr * (1 - COMMISSION))) * 100));
          transfers = [{ account: publisher.razorpayAccountId, amount: sharePaise, currency: 'INR', on_hold: false, notes: { courseId: course.id, kind: 'creator_share' } }];
        }
        let order;
        if (RZP_LIVE) { try { const o = await rzpCreateOrder(paise, `cf_${course.id}`.slice(0, 30), transfers); order = { orderId: o.id, amount: o.amount, mock: false }; } catch {} }
        if (!order) order = { orderId: `order_mock_${crypto.randomBytes(6).toString('hex')}`, amount: paise, mock: true };
        const orders = await load('orders');
        orders.unshift({ orderId: order.orderId, courseId: course.id, buyerId: uid, amountInr: course.priceInr, createdAt: Date.now() });
        await save('orders', orders);
        return send(res, req, 200, { orderId: order.orderId, amount: order.amount, currency: 'INR', keyId: RZP_KEY_ID, mock: order.mock });
      }
      // Razorpay order for a CourseForge Pro subscription (platform keeps 100%).
      if (m === 'POST' && p === '/payments/create-pro-order') {
        const allowed = { 199: 'monthly', 1499: 'yearly' }; // server-side prices
        const amountInr = Number(body.amountInr) || 0;
        if (!allowed[amountInr]) return send(res, req, 400, { error: 'invalid plan' });
        const paise = amountInr * 100;
        let order;
        if (RZP_LIVE) { try { const o = await rzpCreateOrder(paise, `cfpro_${Date.now()}`.slice(0, 30)); order = { orderId: o.id, amount: o.amount, mock: false }; } catch {} }
        if (!order) order = { orderId: `order_mock_${crypto.randomBytes(6).toString('hex')}`, amount: paise, mock: true };
        const orders = await load('orders');
        orders.unshift({ orderId: order.orderId, kind: 'pro', plan: allowed[amountInr], buyerId: uid, amountInr, createdAt: Date.now() });
        await save('orders', orders);
        return send(res, req, 200, { orderId: order.orderId, amount: order.amount, currency: 'INR', keyId: RZP_KEY_ID, mock: order.mock });
      }
      if (m === 'POST' && p === '/payments/verify') {
        const orders = await load('orders');
        const order = orders.find((o) => o.orderId === body.orderId && o.buyerId === uid);
        if (!order) return send(res, req, 400, { error: 'unknown order' });
        const real = RZP_LIVE && !ALLOW_MOCK_PAYMENTS;
        if (real) {
          if (!rzpVerify(body.orderId, body.paymentId, body.signature))
            return send(res, req, 400, { error: 'signature verification failed' });
        } // else: dev/test simulated completion allowed
        // Pro subscription order → flip the user's Pro flag, done.
        if (order.kind === 'pro') {
          const users = await load('users');
          const u = users.find((x) => x.id === uid);
          if (u) { u.pro = true; await save('users', users); }
          return send(res, req, 200, { ok: true, pro: true });
        }
        const purchases = await load('purchases');
        purchases.unshift({ id: crypto.randomUUID(), courseId: order.courseId, buyerId: uid, orderId: order.orderId, amountInr: order.amountInr, at: Date.now() });
        await save('purchases', purchases);
        const published = await load('published');
        const course = published.find((c) => c.id === order.courseId);
        if (course) {
          course.enrollmentsCount = (course.enrollmentsCount || 0) + 1; await save('published', published);
          const earnings = await load('earnings');
          const row = earnings.find((e) => e.publisherId === course.publisherId);
          const add = course.publisherShare || 0;
          if (row) row.totalInr += add; else earnings.push({ publisherId: course.publisherId, totalInr: add });
          await save('earnings', earnings);
        }
        return send(res, req, 200, { ok: true });
      }
      return send(res, req, 404, { error: 'not found' });
    }

    // ── Admin ──
    if (p.startsWith('/admin/')) {
      if (PROD && ADMIN_TOKEN === 'admin-dev') return send(res, req, 503, { error: 'admin disabled: set a strong ADMIN_TOKEN' });
      if (!isAdmin(req)) return send(res, req, 401, { error: 'admin token required' });
      if (m === 'GET' && p === '/admin/pending') {
        const [published, users] = [await load('published'), await load('users')];
        return send(res, req, 200, { courses: published.filter((c) => c.status === 'pending_review').map((c) => enrich(c, users)) });
      }
      const body = await readBody(req);
      if (body.__big) return send(res, req, 413, { error: 'payload too large' });
      if (m === 'POST' && p === '/admin/review') {
        const published = await load('published');
        const c = published.find((x) => x.id === body.courseId);
        if (!c) return send(res, req, 404, { error: 'not found' });
        c.status = body.action === 'approve' ? 'published' : 'rejected'; c.reviewedAt = Date.now();
        await save('published', published);
        return send(res, req, 200, { ok: true, status: c.status });
      }
      if (m === 'POST' && p === '/admin/verify-publisher') {
        const users = await load('users');
        const u = users.find((x) => x.id === body.userId);
        if (!u) return send(res, req, 404, { error: 'not found' });
        u.verifiedPublisher = body.verified !== false; await save('users', users);
        return send(res, req, 200, { ok: true, verifiedPublisher: u.verifiedPublisher });
      }
      return send(res, req, 404, { error: 'not found' });
    }

    return send(res, req, 404, { error: 'not found' });
  } catch (e) {
    console.error('[500]', p, String(e && e.message)); // detail stays server-side
    return send(res, req, 500, { error: 'internal error' });
  }
});

if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT);
}
