## 2025-05-15 - Optimize Join Operations with Map Lookups
**Learning:** Performing `Array.find()` inside a `map()` loop creates an $O(N \times M)$ complexity, which degrades quickly as data grows. Converting the lookup array into a `Map` before the loop reduces complexity to $O(N + M)$ by providing $O(1)$ lookups.
**Action:** Always check for nested searches in bulk data transformation routes. Use a `Map` for lookups when joining datasets in memory.
