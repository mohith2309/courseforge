## 2025-05-15 - Optimized bulk enrichment and added datastore caching
**Learning:** Bulk enrichment using nested $O(N)$ searches in a $map()$ loop creates $O(N \times M)$ complexity, which degrades significantly as the number of users and courses grows. Synchronous disk I/O on every request without caching introduces unnecessary latency.
**Action:** Use a `Map` to perform $O(1)$ lookups during bulk enrichment, reducing complexity to $O(N+M)$. Implement an in-memory `_cache` for the file-based datastore to minimize disk I/O and reduce response times.
