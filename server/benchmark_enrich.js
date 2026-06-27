const crypto = require('crypto');

const NUM_USERS = 5000;
const NUM_COURSES = 1000;

const users = Array.from({ length: NUM_USERS }).map((_, i) => ({
  id: `user_${i}`,
  name: `User ${i}`,
  verifiedPublisher: i % 2 === 0
}));

const courses = Array.from({ length: NUM_COURSES }).map((_, i) => ({
  id: `course_${i}`,
  title: `Course ${i}`,
  publisherId: `user_${Math.floor(Math.random() * NUM_USERS)}`,
  status: 'published'
}));

function enrichOriginal(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

function enrichOptimized(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.time('Original O(C*U)');
const res1 = courses.map(c => enrichOriginal(c, users));
console.timeEnd('Original O(C*U)');

console.time('Optimized O(C+U)');
const userMap = new Map(users.map(u => [u.id, u]));
const res2 = courses.map(c => enrichOptimized(c, userMap));
console.timeEnd('Optimized O(C+U)');
