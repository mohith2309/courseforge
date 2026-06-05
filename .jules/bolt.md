## 2025-05-15 - [O(C*U) to O(C+U) Course Enrichment Optimization]
**Learning:** The course enrichment process in the backend was performing a linear search for the publisher in the `users` array for every course in the catalog. This created an $O(C * U)$ complexity bottleneck that scales poorly as the community grows.
**Action:** Replace linear searches with a `Map`-based lookup. Building the `Map` once per request ($O(U)$) and performing $O(1)$ lookups for each course results in an overall $O(C + U)$ complexity, providing a significant speedup (measured ~9.5x with 10k users/1k courses).
