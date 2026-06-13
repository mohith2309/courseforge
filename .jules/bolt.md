## 2024-05-24 - [O(C*U) to O(C+U) via Map Lookups for Enrichment]
**Learning:** In the backend `server.js`, dataset enrichment functions that join data via array iteration (e.g., `users.find()`) result in an $O(N \times M)$ complexity. When scaling to 5000+ items, this causes substantial event-loop blocking (Node.js latency from ~17ms to over 240ms).
**Action:** Always pre-compute a `Map` structure for lookup datasets (`new Map(users.map(u => [u.id, u]))`) before running enrichment on large collections to maintain an $O(N + M)$ operational complexity.
