const { performance } = require('perf_hooks');

// Mock data
const users = [];
for (let i = 0; i < 2000; i++) {
  users.push({ id: `u${i}`, name: `User ${i}`, verifiedPublisher: i % 10 === 0 });
}

const courses = [];
for (let i = 0; i < 500; i++) {
  courses.push({ id: `c${i}`, publisherId: `u${Math.floor(Math.random() * 2000)}` });
}

function enrichOld(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

function enrichNew(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.log(`Benchmarking enrich with ${courses.length} courses and ${users.length} users (repeated 100x)...`);

// Test Old
const startOld = performance.now();
for (let i = 0; i < 100; i++) {
  courses.map(c => enrichOld(c, users));
}
const endOld = performance.now();
const oldTime = endOld - startOld;
console.log(`Old (Array.find): ${oldTime.toFixed(2)}ms`);

// Test New
const startNew = performance.now();
const usersMap = new Map(users.map(u => [u.id, u]));
for (let i = 0; i < 100; i++) {
  courses.map(c => enrichNew(c, usersMap));
}
const endNew = performance.now();
const newTime = endNew - startNew;
console.log(`New (Map.get): ${newTime.toFixed(2)}ms`);
console.log(`Speedup: ${(oldTime / newTime).toFixed(2)}x`);
