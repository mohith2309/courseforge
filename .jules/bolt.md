## 2024-06-12 - Prevent O(n^2) Complexity in Array Enrichment
**Learning:** Using `Array.prototype.find()` inside a `.map()` loop for bulk list enrichment (like mapping publisher details onto courses) results in O(n * m) time complexity, which causes severe latency scaling issues for large datasets. Benchmarks previously noted this dropped response time from ~192ms to ~14ms at 5,000 items.
**Action:** Always pre-compute a `Map` from the secondary array (`new Map(users.map(u => [u.id, u]))`) before the iteration, reducing time complexity to O(n + m) via O(1) map lookups.
