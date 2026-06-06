## 2025-05-15 - Course Enrichment Complexity Optimization
**Learning:** In endpoints that join data from multiple stores (like courses and users), performing an array search for every item creates O(N*M) complexity. This becomes a bottleneck as the dataset grows.
**Action:** Use a `Map` for $O(1)$ lookups when performing joins or enrichment to achieve $O(N+M)$ complexity.
