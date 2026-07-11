const users = Array.from({length: 2000}, (_, i) => ({id: i.toString(), name: 'User', verifiedPublisher: true}));
const courses = Array.from({length: 500}, (_, i) => ({id: i.toString(), publisherId: (i % 2000).toString(), status: 'published'}));

function enrichOld(entry, users) {
  const u = users.find((x) => x.id === entry.publisherId);
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

function enrichNew(entry, users) {
  let u;
  if (users instanceof Map) {
    u = users.get(entry.publisherId);
  } else {
    u = users.find((x) => x.id === entry.publisherId);
  }
  return { ...entry, publisherName: u ? u.name : 'Unknown', publisherVerified: u ? Boolean(u.verifiedPublisher) : false };
}

console.time('old');
courses.map(c => enrichOld(c, users));
console.timeEnd('old');

console.time('new');
const usersMap = new Map(users.map(u => [u.id, u]));
courses.map(c => enrichNew(c, usersMap));
console.timeEnd('new');
