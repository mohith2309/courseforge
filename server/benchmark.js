const crypto = require('crypto');

// Setup mock data
const numUsers = 5000;
const numCourses = 1000;

const users = Array.from({ length: numUsers }, (_, i) => ({
  id: `user_${i}`,
  name: `User ${i}`,
  verifiedPublisher: i % 2 === 0
}));

const courses = Array.from({ length: numCourses }, (_, i) => ({
  id: `course_${i}`,
  publisherId: `user_${Math.floor(Math.random() * numUsers)}`,
  title: `Course ${i}`
}));

// Original O(N) function
function enrichSlow(entry, usersList) {
  const u = usersList.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// Optimized O(1) function
function enrichFast(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.log(`Benchmarking enrichment with ${numCourses} courses and ${numUsers} users...`);

const startSlow = performance.now();
const resultSlow = courses.map(c => enrichSlow(c, users));
const timeSlow = performance.now() - startSlow;
console.log(`Original O(N) approach: ${timeSlow.toFixed(2)}ms`);

const startFast = performance.now();
const userMap = new Map(users.map(u => [u.id, u]));
const resultFast = courses.map(c => enrichFast(c, userMap));
const timeFast = performance.now() - startFast;
console.log(`Optimized O(1) approach: ${timeFast.toFixed(2)}ms`);

console.log(`Speedup: ${(timeSlow / timeFast).toFixed(2)}x`);
