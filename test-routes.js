const assert = require('assert');

// Mock load function for testing the logic
const mockUsers = [{ id: 'u1', name: 'User 1', verifiedPublisher: true }, { id: 'u2', name: 'User 2', verifiedPublisher: false }];
const mockPublished = [
  { id: 'c1', title: 'Course 1', publisherId: 'u1', status: 'published' },
  { id: 'c2', title: 'Course 2', publisherId: 'u2', status: 'pending_review' },
  { id: 'c3', title: 'Course 3', publisherId: 'u3', status: 'published' }
];

async function load(key) {
    if (key === 'published') return mockPublished;
    if (key === 'users') return mockUsers;
    return [];
}

function enrich(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

async function testPublishedRoute() {
    const [published, users] = [await load('published'), await load('users')];
    const usersMap = new Map(users.map((u) => [u.id, u]));
    const result = published.filter((c) => c.status === 'published').map((c) => enrich(c, usersMap));

    assert.strictEqual(result.length, 2);
    assert.strictEqual(result[0].publisherName, 'User 1');
    assert.strictEqual(result[0].publisherVerified, true);
    assert.strictEqual(result[1].publisherName, 'Unknown');
    assert.strictEqual(result[1].publisherVerified, false);
}

async function testAdminPendingRoute() {
    const [published, users] = [await load('published'), await load('users')];
    const usersMap = new Map(users.map((u) => [u.id, u]));
    const result = published.filter((c) => c.status === 'pending_review').map((c) => enrich(c, usersMap));

    assert.strictEqual(result.length, 1);
    assert.strictEqual(result[0].publisherName, 'User 2');
    assert.strictEqual(result[0].publisherVerified, false);
}

async function runTests() {
    await testPublishedRoute();
    await testAdminPendingRoute();
    console.log("Custom route logic tests passed!");
}

runTests();
