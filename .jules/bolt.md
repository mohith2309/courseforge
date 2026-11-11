## 2025-05-11 - O(N^2) Bottleneck in Course Enrichment
**Learning:** Using `Array.find` inside a `map` loop for enriching course data with user info causes an O(N*M) complexity which scales poorly when both the number of courses and users grow.
**Action:** Replace `Array.find` lookups with `Map` lookups inside loops to achieve O(N+M) complexity, resulting in significant (~8.5x) speedups.
