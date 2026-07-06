const test = require('node:test');
const assert = require('node:assert');
const { spawnSync } = require('node:child_process');
const path = require('node:path');

// Set env before requiring to ensure exports are active
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';
process.env.ADMIN_TOKEN = 'test-admin';

const { corsFor, verifyToken, signToken, safeEq } = require('./server.js');

test('Security Headers in corsFor', () => {
  const req = { headers: {} };
  const headers = corsFor(req);

  assert.strictEqual(headers['X-Content-Type-Options'], 'nosniff');
  assert.strictEqual(headers['X-Frame-Options'], 'DENY');
  assert.strictEqual(headers['Referrer-Policy'], 'strict-origin-when-cross-origin');
  assert.ok(headers['Content-Security-Policy'].includes("default-src 'none'"));
});

test('verifyToken should protect against forged signatures', () => {
  const uid = 'user-123';
  const token = signToken(uid);
  assert.strictEqual(verifyToken(token), uid);

  const [payload, sig] = token.split('.');
  const forgedSig = 'forged-signature';
  assert.strictEqual(verifyToken(`${payload}.${forgedSig}`), null);
});

test('safeEq should be timing-safe (length check)', () => {
  assert.strictEqual(safeEq('aaa', 'aaa'), true);
  assert.strictEqual(safeEq('aaa', 'bbb'), false);
  assert.strictEqual(safeEq('aaa', 'aaaa'), false);
});

test('Fail-closed startup check in production', () => {
  const serverPath = path.join(__dirname, 'server.js');

  // Case 1: Default ADMIN_TOKEN in production should fail
  const result1 = spawnSync('node', [serverPath], {
    env: { ...process.env, NODE_ENV: 'production', ADMIN_TOKEN: 'admin-dev', JWT_SECRET: 'secure-secret' }
  });
  assert.strictEqual(result1.status, 1, 'Should exit with 1 when ADMIN_TOKEN is default');
  assert.ok(result1.stderr.toString().includes('CRITICAL'), 'Should log CRITICAL error');

  // Case 2: Default JWT_SECRET in production should fail
  const result2 = spawnSync('node', [serverPath], {
    env: { ...process.env, NODE_ENV: 'production', ADMIN_TOKEN: 'secure-token', JWT_SECRET: 'dev-secret' }
  });
  assert.strictEqual(result2.status, 1, 'Should exit with 1 when JWT_SECRET is default');

  // Case 3: Mock payments enabled in production should fail
  const result3 = spawnSync('node', [serverPath], {
    env: { ...process.env, NODE_ENV: 'production', ADMIN_TOKEN: 'secure-token', JWT_SECRET: 'secure-secret', ALLOW_MOCK_PAYMENTS: 'true' }
  });
  assert.strictEqual(result3.status, 1, 'Should exit with 1 when mock payments enabled');
});
