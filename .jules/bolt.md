## 2025-01-24 - Bulk Course Enrichment Complexity
**Learning:** Bulk enrichment of courses with publisher details using `Array.find()` inside a `map()` loop leads to $O(C \times U)$ complexity. This becomes a significant bottleneck as the user and course counts grow. Using a `Map` for lookups reduces this to $O(C + U)$. This specific area in `server.js` seems prone to regression if not documented.
**Action:** Always prefer `Map` for lookups when joining two datasets in-memory. Keep the `enrich` function flexible by supporting both `Map` and `Array` (with a preference for `Map` in hot paths).
