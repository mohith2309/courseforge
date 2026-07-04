const crypto = require('crypto');

// Current implementation
function enrichOld(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Optimized implementation (proposed)
function enrichNew(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Mock data
const NUM_USERS = 5000;
const NUM_COURSES = 1000;

console.log(`Generating ${NUM_USERS} users and ${NUM_COURSES} courses...`);
const users = [];
for (let i = 0; i < NUM_USERS; i++) {
  users.push({ id: `user_${i}`, name: `User ${i}`, verifiedPublisher: i % 10 === 0 });
}

const courses = [];
for (let i = 0; i < NUM_COURSES; i++) {
  courses.push({
    id: `course_${i}`,
    publisherId: `user_${Math.floor(Math.random() * NUM_USERS)}`,
    status: 'published',
    title: `Course ${i}`
  });
}

// Baseline
console.log('--- Baseline (Array.find) ---');
const startOld = performance.now();
const enrichedOld = courses.map(c => enrichOld(c, users));
const endOld = performance.now();
console.log(`Time: ${(endOld - startOld).toFixed(2)}ms`);

// Optimized
console.log('--- Optimized (Map.get) ---');
const startMapSetup = performance.now();
const userMap = new Map(users.map(u => [u.id, u]));
const endMapSetup = performance.now();
const startNew = performance.now();
const enrichedNew = courses.map(c => enrichNew(c, userMap));
const endNew = performance.now();
console.log(`Map Setup: ${(endMapSetup - startMapSetup).toFixed(2)}ms`);
console.log(`Enrichment: ${(endNew - startNew).toFixed(2)}ms`);
console.log(`Total Optimized: ${(endNew - startMapSetup).toFixed(2)}ms`);

// Verification
if (JSON.stringify(enrichedOld) === JSON.stringify(enrichedNew)) {
  console.log('Verification: SUCCESS (Results match)');
} else {
  console.error('Verification: FAILED (Results differ)');
  process.exit(1);
}

const speedup = (endOld - startOld) / (endNew - startMapSetup);
console.log(`Speedup: ${speedup.toFixed(2)}x`);
