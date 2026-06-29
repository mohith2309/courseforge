const assert = require('assert');

// Original
function enrichOriginal(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Optimized
function enrichOptimized(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Generate data
const usersArray = [];
for (let i = 0; i < 5000; i++) {
  usersArray.push({ id: `user-${i}`, name: `User ${i}`, verifiedPublisher: i % 2 === 0 });
}

const coursesArray = [];
for (let i = 0; i < 1000; i++) {
  coursesArray.push({ id: `course-${i}`, title: `Course ${i}`, publisherId: `user-${Math.floor(Math.random() * 5000)}`, status: 'published' });
}

// Benchmark Original
console.time('Original');
const originalEnriched = coursesArray.map(c => enrichOriginal(c, usersArray));
console.timeEnd('Original');

// Benchmark Optimized
console.time('Optimized');
const usersMap = new Map(usersArray.map(u => [u.id, u]));
const optimizedEnriched = coursesArray.map(c => enrichOptimized(c, usersMap));
console.timeEnd('Optimized');

assert.deepEqual(originalEnriched, optimizedEnriched);
console.log("Validation passed!");
