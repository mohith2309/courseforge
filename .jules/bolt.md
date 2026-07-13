## 2025-05-22 - Optimized Course Enrichment with Map Lookups
**Learning:** The course enrichment process in the backend used an O(N * M) approach by performing an `Array.find()` for each course to get the publisher details. This becomes a significant bottleneck as the number of courses and users grow.
**Action:** Use a `Map` to pre-index the secondary data (users) for O(1) lookups. In `server/server.js`, I updated the `enrich` function to support `Map` and optimized the `/courses/published` and `/admin/pending` routes.
