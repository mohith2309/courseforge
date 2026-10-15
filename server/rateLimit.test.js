const test = require('node:test');
const assert = require('node:assert');
const { rateLimit, buckets } = require('./server.js');

test('rateLimit unit tests', async (t) => {
  t.beforeEach(() => {
    buckets.clear();
  });

  await t.test('allows requests below the limit', () => {
    const key = 'test-ip-1';
    const limit = 3;
    const windowMs = 60000;

    assert.strictEqual(rateLimit(key, limit, windowMs), true);
    assert.strictEqual(rateLimit(key, limit, windowMs), true);
    assert.strictEqual(rateLimit(key, limit, windowMs), true);
  });

  await t.test('blocks requests exceeding the limit', () => {
    const key = 'test-ip-2';
    const limit = 2;
    const windowMs = 60000;

    assert.strictEqual(rateLimit(key, limit, windowMs), true);
    assert.strictEqual(rateLimit(key, limit, windowMs), true);
    assert.strictEqual(rateLimit(key, limit, windowMs), false);
    assert.strictEqual(rateLimit(key, limit, windowMs), false);
  });

  await t.test('expires old requests outside the window', async () => {
    const key = 'test-ip-3';
    const limit = 1;
    const windowMs = 100; // 100ms window

    assert.strictEqual(rateLimit(key, limit, windowMs), true); // 1st request, count=1
    assert.strictEqual(rateLimit(key, limit, windowMs), false); // 2nd request, blocked

    // Wait for the window to expire
    await new Promise((resolve) => setTimeout(resolve, 150));

    // After expiration, should be allowed again
    assert.strictEqual(rateLimit(key, limit, windowMs), true);
  });

  await t.test('different keys operate independently', () => {
    const key1 = 'test-ip-4';
    const key2 = 'test-ip-5';
    const limit = 1;
    const windowMs = 60000;

    assert.strictEqual(rateLimit(key1, limit, windowMs), true);
    assert.strictEqual(rateLimit(key1, limit, windowMs), false);

    assert.strictEqual(rateLimit(key2, limit, windowMs), true); // key2 is unaffected
    assert.strictEqual(rateLimit(key2, limit, windowMs), false);
  });
});
