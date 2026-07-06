const assert = require('assert');

function enrich(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

const usersArray = [{id: '1', name: 'Alice'}];
const usersMap = new Map([['1', {id: '1', name: 'Alice'}]]);
const course = {id: 'c1', publisherId: '1'};

const res1 = enrich(course, usersArray);
const res2 = enrich(course, usersMap);

assert.strictEqual(res1.publisherName, 'Alice');
assert.strictEqual(res2.publisherName, 'Alice');

console.log("Success");
