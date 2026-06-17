## 2026-06-17 - O(C * U) Bottleneck in Course Enrichment
**Learning:** The `enrich` function in `server/server.js` performs an (U)$ lookup using `Array.find()` for every course. In bulk endpoints like `/courses/published` and `/admin/pending`, this results in (C \times U)$ complexity. Benchmarking 1,000 courses and 5,000 users showed ~140ms latency.
**Action:** Convert the `users` list to a `Map` for (1)$ lookups when performing bulk enrichment. This reduces processing time to < 1ms for the same data size.
