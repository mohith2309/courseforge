## 2026-06-23 - Optimize course enrichment with Map-based lookups
**Learning:** Performing `Array.find()` inside a `map()` loop over courses to find publishers creates an O(C * U) complexity bottleneck.
**Action:** Always convert the lookup array (users) into a `Map` before the loop to achieve O(C + U) complexity with O(1) lookups.
