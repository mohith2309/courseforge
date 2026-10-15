const { performance } = require('perf_hooks');

const NUM_COURSES = 1000;
const NUM_USERS = 5000;

const courses = Array.from({ length: NUM_COURSES }, (_, i) => ({
  id: `course_${i}`,
  publisherId: `user_${Math.floor(Math.random() * NUM_USERS)}`,
  status: 'published'
}));

const users = Array.from({ length: NUM_USERS }, (_, i) => ({
  id: `user_${i}`,
  name: `User ${i}`,
  verifiedPublisher: Math.random() > 0.5
}));

function enrich_old(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

function enrich_new(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Benchmark old
const startOld = performance.now();
const resultOld = courses.map(c => enrich_old(c, users));
const endOld = performance.now();
console.log(`Old enrich: ${(endOld - startOld).toFixed(2)}ms`);

// Benchmark new
const startNewMap = performance.now();
const userMap = new Map(users.map(u => [u.id, u]));
const resultNew = courses.map(c => enrich_new(c, userMap));
const endNewMap = performance.now();
console.log(`New enrich (with Map creation): ${(endNewMap - startNewMap).toFixed(2)}ms`);
