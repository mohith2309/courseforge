const { performance } = require('perf_hooks');

// Mock data
const numUsers = 2000;
const numCourses = 500;

const users = [];
for (let i = 0; i < numUsers; i++) {
  users.push({ id: `user_${i}`, name: `User ${i}`, verifiedPublisher: i % 2 === 0 });
}

const published = [];
for (let i = 0; i < numCourses; i++) {
  published.push({ id: `course_${i}`, publisherId: `user_${Math.floor(Math.random() * numUsers)}`, status: 'published' });
}

// Old implementation
function enrichOld(entry, usersArr) {
  const u = usersArr.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// New implementation
function enrichNew(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.log('--- Benchmarking ---');

// Benchmark Old
const startOld = performance.now();
for (let j = 0; j < 100; j++) { // 100 iterations to make it measurable
  published.filter((c) => c.status === 'published').map((c) => enrichOld(c, users));
}
const endOld = performance.now();
console.log(`Old (Array.find): ${(endOld - startOld).toFixed(2)} ms`);

// Benchmark New
const startNew = performance.now();
for (let j = 0; j < 100; j++) {
  const usersMap = new Map(users.map(u => [u.id, u]));
  published.filter((c) => c.status === 'published').map((c) => enrichNew(c, usersMap));
}
const endNew = performance.now();
console.log(`New (Map.get): ${(endNew - startNew).toFixed(2)} ms`);

console.log(`Speedup: ${((endOld - startOld) / (endNew - startNew)).toFixed(2)}x`);
