## 2026-11-10 - Course enrichment nested array lookup optimization
**Learning:** In course listing endpoints (`/courses/published` and `/admin/pending`), calling `enrich` on each course while passing the raw `users` array resulted in an O(N * M) nested scan (`Array.prototype.find`). With larger user and course catalogs, this introduces unnecessary CPU latency on read requests.
**Action:** Index lookup lists into a `Map` prior to iterating or mapping over collections, reducing overall complexity to O(N + M) and enabling O(1) key lookups.
