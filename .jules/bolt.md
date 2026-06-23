## 2024-06-23 - Optimize bulk course enrichment

**Learning:** When generating large API payloads (like `/courses/published` and `/admin/pending`), calling `Array.prototype.find()` inside a `Array.prototype.map()` loop creates an $O(N \times M)$ complexity bottleneck where N is courses and M is users.
**Action:** Convert the lookup array into a `Map` before the mapping iteration to achieve $O(1)$ lookups, reducing overall complexity to $O(N + M)$. The `enrich()` function should always check if the `users` argument is an instance of `Map` first.
