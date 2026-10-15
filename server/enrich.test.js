const test = require('node:test');
const assert = require('node:assert');
const { enrich } = require('./server.js');

test('enrich works with Array-based users', () => {
  const users = [
    { id: 'u1', name: 'Alice', verifiedPublisher: true },
    { id: 'u2', name: 'Bob', verifiedPublisher: false }
  ];
  const entry = { title: 'Course 1', publisherId: 'u1' };

  const result = enrich(entry, users);

  assert.strictEqual(result.publisherName, 'Alice');
  assert.strictEqual(result.publisherVerified, true);
});

test('enrich works with Map-based users', () => {
  const users = new Map([
    ['u1', { id: 'u1', name: 'Alice', verifiedPublisher: true }],
    ['u2', { id: 'u2', name: 'Bob', verifiedPublisher: false }]
  ]);
  const entry = { title: 'Course 1', publisherId: 'u2' };

  const result = enrich(entry, users);

  assert.strictEqual(result.publisherName, 'Bob');
  assert.strictEqual(result.publisherVerified, false);
});

test('enrich handles unknown publisher in Array', () => {
  const users = [{ id: 'u1', name: 'Alice' }];
  const entry = { title: 'Course 1', publisherId: 'u2' };

  const result = enrich(entry, users);

  assert.strictEqual(result.publisherName, 'Unknown');
  assert.strictEqual(result.publisherVerified, false);
});

test('enrich handles unknown publisher in Map', () => {
  const users = new Map([['u1', { id: 'u1', name: 'Alice' }]]);
  const entry = { title: 'Course 1', publisherId: 'u2' };

  const result = enrich(entry, users);

  assert.strictEqual(result.publisherName, 'Unknown');
  assert.strictEqual(result.publisherVerified, false);
});
