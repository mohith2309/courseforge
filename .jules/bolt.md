## 2025-05-22 - [Optimizing Course Enrichment]
**Learning:** Bulk course enrichment using `Array.find()` for publisher lookup scales poorly as O(C*U), which becomes a significant bottleneck as the number of courses (C) and users (U) grows.
**Action:** Always prefer Map-based lookups for O(1) retrieval in hot paths or bulk operations to achieve O(C+U) complexity.
