## 2026-06-06 - [O(C*U) to O(C+U) lookup optimization]
**Learning:** Nested lookups in large datasets can cause significant performance degradation. Using a Hash Map (JavaScript `Map`) for O(1) lookups instead of repeatedly searching an array (O(n)) is a standard but high-impact optimization for API endpoints that enrich data from multiple sources.
**Action:** Always check for nested loops or `find()` calls in frequently accessed endpoints and replace them with `Map` lookups when enriching a collection with data from another.
