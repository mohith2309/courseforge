## 2026-06-13 - [O(C+U) Course Enrichment]
**Learning:** The course catalog enrichment process was $O(C \times U)$ because it performed a linear search (`Array.find`) through all users for every course. For 1,000 items, this resulted in ~66ms latency. Switching to a `Map`-based lookup reduced this to ~4ms ($O(C+U)$).
**Action:** Always use `Map` or `Set` for lookups when joining datasets in-memory within Node.js routes to maintain $O(N)$ complexity and prevent event loop blocking as data grows.
