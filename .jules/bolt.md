## 2025-05-15 - Optimize bulk enrichment with Map-based lookups
**Learning:** Performing `Array.find()` inside a `map()` loop (e.g., for attaching publisher names to courses) creates $O(C \times U)$ complexity. Converting the lookup array into a `Map` before the loop reduces complexity to $O(C + U)$ with $O(1)$ lookups.
**Action:** Always prefer `Map` for bulk lookups when enriching datasets from a secondary source in performance-sensitive routes.
