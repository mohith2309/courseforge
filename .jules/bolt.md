## 2025-05-14 - Bulk Course Enrichment Complexity Bottleneck
**Learning:** Performing `Array.find()` inside a `map()` loop for bulk data enrichment creates $O(C \times U)$ complexity (where $C$ is courses and $U$ is users). This scales poorly as the user base grows, leading to noticeable latency on catalog and admin endpoints.
**Action:** Convert the lookup array into a `Map` before the loop to reduce complexity to $O(C + U)$ with $O(1)$ lookups. Ensure the enrichment helper supports both `Map` and `Array` for flexibility.
