const assert = require('assert');

function enrich(entry, users) {
  const u = users instanceof Map ? users.get(entry.publisherId) : users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

const usersArray = [{id: '1', name: 'Alice', verifiedPublisher: true}, {id: '2', name: 'Bob', verifiedPublisher: false}];
const usersMap = new Map(usersArray.map(u => [u.id, u]));
const entry = {id: '100', publisherId: '1'};

const enrichedArray = enrich(entry, usersArray);
const enrichedMap = enrich(entry, usersMap);
assert.deepEqual(enrichedArray, enrichedMap);
console.log("Success!");
