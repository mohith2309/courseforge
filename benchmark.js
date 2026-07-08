const crypto = require('crypto');

// Setup mock data
const NUM_USERS = 5000;
const NUM_COURSES = 1000;

const users = [];
for(let i=0; i<NUM_USERS; i++) {
  users.push({ id: crypto.randomUUID(), name: `User ${i}`, verifiedPublisher: i%2===0 });
}

const published = [];
for(let i=0; i<NUM_COURSES; i++) {
  published.push({ id: crypto.randomUUID(), title: `Course ${i}`, publisherId: users[Math.floor(Math.random() * NUM_USERS)].id, status: 'published' });
}

// Old enrich
function enrichOld(entry, usersArr) {
  const u = usersArr.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

// New enrich
function enrichNew(entry, usersObj) {
  const u = usersObj instanceof Map ? usersObj.get(entry.publisherId) : usersObj.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.log("Measuring old approach (O(N^2))...");
let start = performance.now();
let resultOld = published.filter(c => c.status === 'published').map(c => enrichOld(c, users));
let oldTime = performance.now() - start;
console.log(`Old time: ${oldTime.toFixed(2)}ms`);

console.log("Measuring new approach (O(N) Map)...");
start = performance.now();
const usersMap = new Map(users.map(u => [u.id, u]));
let resultNew = published.filter(c => c.status === 'published').map(c => enrichNew(c, usersMap));
let newTime = performance.now() - start;
console.log(`New time: ${newTime.toFixed(2)}ms`);
