## 2026-06-24 - Course Enrichment and Datastore Caching
**Learning:** Bulk course enrichment using `Array.find()` inside a `map()` loop creates $O(C \times U)$ complexity, which causes significant latency as the catalog and user base grow. Converting the lookup array into a `Map` before the loop reduces complexity to $O(C + U)$. Additionally, redundant disk/network I/O in the datastore layer (`load`/`save`) can be mitigated with a simple in-memory cache, though it must be careful not to cache transient errors.

**Action:** Always prefer Map-based lookups for bulk enrichment operations. Implement in-memory caching for datastores with a strategy that avoids caching failures to ensure robustness.
