
## 2024-05-18 - Map-based lookup for course enrichment
**Learning:** The `enrich` function in `server/server.js` was using O(N) array search `.find()` to attach publisher information to every course, leading to an overall O(C * U) complexity when listing courses or pending reviews. With a large number of courses and users, this caused a significant performance bottleneck.
**Action:** Implemented a pattern to pre-instantiate a `Map` of users and pass it down to `enrich` (`users instanceof Map ? users.get(...) : users.find(...)`). Always prefer O(1) Map lookups for N+1 enrichment scenarios to maintain O(C + U) complexity.
