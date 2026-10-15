## 2026-06-16 - Optimize bulk course enrichment endpoints to O(C+U)
**Learning:** Performing `Array.find()` inside a `map()` loop creates $O(C \times U)$ complexity, which can be a significant bottleneck for bulk operations like course enrichment where C (courses) and U (users) are large.
**Action:** Convert the lookup array into a `Map` before the loop to reduce complexity to $O(C + U)$ with $O(1)$ lookups inside the loop.
