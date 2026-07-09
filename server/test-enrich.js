const assert = require('assert');

function enrich(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

const users = [{ id: 'u1', name: 'Alice', verifiedPublisher: true }, { id: 'u2', name: 'Bob' }];
const entry = { id: 'c1', publisherId: 'u1', title: 'Course 1' };

const arrResult = enrich(entry, users);
assert.strictEqual(arrResult.publisherName, 'Alice');
assert.strictEqual(arrResult.publisherVerified, true);

const mapUsers = new Map(users.map(u => [u.id, u]));
const mapResult = enrich(entry, mapUsers);
assert.strictEqual(mapResult.publisherName, 'Alice');
assert.strictEqual(mapResult.publisherVerified, true);

console.log("Tests passed!");
