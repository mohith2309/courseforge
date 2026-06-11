const assert = require('assert');
const crypto = require('crypto');

// Set up test environment variables
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-secret';

const { hmac, b64url } = require('./server.js');

console.log("Running Tests for hmac and b64url...");

// Test b64url
assert.strictEqual(b64url("hello"), "aGVsbG8", "b64url should encode 'hello'");

// Create static test vectors for known inputs
const testInput1 = "my-test-payload";
const testInput2 = JSON.stringify({ uid: "user123", exp: 1234567890 });
const testInput3 = "";

// Dynamic expected (to ensure standard match)
const dynExpected1 = crypto.createHmac('sha256', process.env.JWT_SECRET).update(testInput1).digest('base64url');
const dynExpected2 = crypto.createHmac('sha256', process.env.JWT_SECRET).update(testInput2).digest('base64url');
const dynExpected3 = crypto.createHmac('sha256', process.env.JWT_SECRET).update(testInput3).digest('base64url');

// Test hmac against known crypto standard logic
assert.strictEqual(hmac(testInput1), dynExpected1, "hmac should match crypto standard output for plain string");
assert.strictEqual(hmac(testInput2), dynExpected2, "hmac should match crypto standard output for JSON string");
assert.strictEqual(hmac(testInput3), dynExpected3, "hmac should handle empty string");

// Test hmac against static vectors (to ensure output never changes silently)
assert.strictEqual(hmac(testInput1), "HNkLyXMl9KDtSMjFFSfnkLtibxBUnJWRruLpnJ-3NHs", "hmac should match static known output for 'my-test-payload'");

// Property testing
const res = hmac(testInput1);
assert.ok(res.length > 0, "hmac should return a non-empty string");
assert.ok(!res.includes('+'), "hmac output should not contain + (base64url requirement)");
assert.ok(!res.includes('/'), "hmac output should not contain / (base64url requirement)");
assert.ok(!res.includes('='), "hmac output should not contain padding (base64url requirement)");

console.log("All tests passed! ✅");
