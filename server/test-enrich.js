const assert = require('assert');

function enrich_old(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

function enrich_new(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// ── Verification ─────────────────────────────────────────────────────────────
const testUsers = [
  { id: 'u1', name: 'Alice', verifiedPublisher: true },
  { id: 'u2', name: 'Bob', verifiedPublisher: false },
];
const testEntry = { id: 'c1', publisherId: 'u1', title: 'Course 1' };

const expected = {
  id: 'c1',
  publisherId: 'u1',
  title: 'Course 1',
  publisherName: 'Alice',
  publisherVerified: true,
};

// Test with Array
assert.deepStrictEqual(enrich_new(testEntry, testUsers), expected, 'Array-based enrich failed');

// Test with Map
const testMap = new Map(testUsers.map(u => [u.id, u]));
assert.deepStrictEqual(enrich_new(testEntry, testMap), expected, 'Map-based enrich failed');

// Test with unknown publisher
const unknownEntry = { id: 'c2', publisherId: 'u99' };
const unknownExpected = { id: 'c2', publisherId: 'u99', publisherName: 'Unknown', publisherVerified: false };
assert.deepStrictEqual(enrich_new(unknownEntry, testUsers), unknownExpected);
assert.deepStrictEqual(enrich_new(unknownEntry, testMap), unknownExpected);

console.log('✅ Verification passed.');

// ── Benchmarking ─────────────────────────────────────────────────────────────
const numUsers = 2000;
const numCourses = 500;
const iterations = 100;

const users = [];
for (let i = 0; i < numUsers; i++) {
  users.push({ id: `user_${i}`, name: `User ${i}`, verifiedPublisher: i % 10 === 0 });
}
const courses = [];
for (let i = 0; i < numCourses; i++) {
  courses.push({ id: `course_${i}`, publisherId: `user_${Math.floor(Math.random() * numUsers)}` });
}

console.log(`Benchmarking with ${numCourses} courses and ${numUsers} users over ${iterations} iterations...`);

// Old: O(N * M)
const startOld = performance.now();
for (let i = 0; i < iterations; i++) {
  courses.map(c => enrich_old(c, users));
}
const endOld = performance.now();
const timeOld = endOld - startOld;
console.log(`Old enrich: ${timeOld.toFixed(2)}ms`);

// New: O(N + M)
const startNew = performance.now();
for (let i = 0; i < iterations; i++) {
  const uMap = new Map(users.map(u => [u.id, u]));
  courses.map(c => enrich_new(c, uMap));
}
const endNew = performance.now();
const timeNew = endNew - startNew;
console.log(`New enrich (including Map creation): ${timeNew.toFixed(2)}ms`);

const speedup = timeOld / timeNew;
console.log(`Speedup: ${speedup.toFixed(2)}x`);

if (speedup < 2) {
  console.warn('⚠️ Speedup was less than 2x. This might not be a significant optimization for these data sizes.');
}
