## 2024-05-18 - Optimize bulk course enrichment to O(C+U)
**Learning:** Performing `Array.prototype.find()` on a large users array for each item in a large courses array during bulk enrichment causes an $O(C \times U)$ performance bottleneck.
**Action:** Always use `new Map(users.map(u => [u.id, u]))` to pre-instantiate a Map and use `Map.prototype.get()` inside `enrich` functions for O(1) lookups, reducing overall complexity to O(C + U).
