
## 2024-05-18 - Optimize course enrichment via Map lookups
**Learning:** Using `Array.find` within `Array.map` leads to O(N*M) complexity. During course enrichment in `/courses/published` and `/admin/pending`, searching an array of users for each course becomes a performance bottleneck for large datasets.
**Action:** Convert the `users` array to a `Map` using `new Map(users.map(u => [u.id, u]))` to achieve O(1) lookups. In `enrich`, support both `Array` and `Map` to prevent breaking other uses, and use the `Map` version in high-traffic endpoints.
