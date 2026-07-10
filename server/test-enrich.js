const { performance } = require('perf_hooks');

// Mocking the enrichment logic for testing outside the server context if needed,
// but here we just want to verify the logic we just wrote.
function enrich(entry, users) {
  // Use O(1) Map lookup if available, otherwise fallback to O(N) search.
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

const numUsers = 1000;
const numCourses = 1000;

const users = Array.from({ length: numUsers }, (_, i) => ({
  id: `u${i}`,
  name: `User ${i}`,
  verifiedPublisher: i % 2 === 0
}));

const courses = Array.from({ length: numCourses }, (_, i) => ({
  id: `c${i}`,
  publisherId: `u${i % numUsers}`
}));

// Baseline (O(N*M))
const start1 = performance.now();
const res1 = courses.map(c => enrich(c, users));
const end1 = performance.now();
const time1 = end1 - start1;

// Optimized (O(N+M))
const start2 = performance.now();
const userMap = new Map(users.map(u => [u.id, u]));
const res2 = courses.map(c => enrich(c, userMap));
const end2 = performance.now();
const time2 = end2 - start2;

console.log(`O(N*M) time: ${time1.toFixed(3)}ms`);
console.log(`O(N+M) time: ${time2.toFixed(3)}ms`);
console.log(`Speedup: ${(time1 / time2).toFixed(2)}x`);

// Verify correctness
const match = res1.every((r, i) =>
  r.publisherName === res2[i].publisherName &&
  r.publisherVerified === res2[i].publisherVerified
);

if (match) {
  console.log('✅ Logic verification passed: Results are identical.');
} else {
  console.log('❌ Logic verification failed: Results differ!');
  process.exit(1);
}
