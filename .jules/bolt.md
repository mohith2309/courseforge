## 2025-05-14 - [O(N^2) complexity in course enrichment]
**Learning:** Mapping users to courses using Array.find results in O(N*M) complexity, which bottlenecks as the database grows.
**Action:** Use a Map for O(1) lookups when decorating lists. Added support for Map to the enrich function and updated route handlers to construct the Map once.
