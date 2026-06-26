## 2024-05-24 - Bulk Enrichment O(N^2) Bottleneck
**Learning:** Bulk enrichment endpoints (`/courses/published` and `/admin/pending`) were repeatedly searching an unindexed user array using `.find()`, resulting in an $O(C \times U)$ complexity. This is a recurring regression risk in this codebase architecture.
**Action:** Always pre-instantiate a `Map` ($O(U)$ construction) when matching external entities in a collection to achieve $O(1)$ lookups, reducing overall complexity to $O(C + U)$. Ensure `enrich` functions support polymorphic data types (`Map` vs `Array`) via runtime checks.
