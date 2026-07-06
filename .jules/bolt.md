## 2025-05-14 - Optimized course enrichment with Map-based user lookups
**Learning:** The `enrich` function was performing a linear search (`Array.find`) on the users array for every course, resulting in O(C*U) complexity. For a catalog of 1,000 courses and 5,000 users, this added significant latency (~60ms) to public and admin routes.
**Action:** Convert the users array to a `Map` before processing lists of courses to achieve O(1) lookups. Implement the `enrich` function to handle both `Map` and `Array` to maintain backward compatibility while allowing for optimized call sites.
