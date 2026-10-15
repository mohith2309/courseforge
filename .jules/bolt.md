
## 2024-07-02 - Array Map enrichment O(N^2) trap
**Learning:** In the `enrich` function, looking up a user in an array of `users` for each course using `find()` results in O(C*U) time complexity, which degrades severely at scale. For 1,000 courses and 5,000 users, it takes ~133ms.
**Action:** When enriching arrays from another list, pre-compute a `Map` of the target objects keyed by their ID. Passing the Map instead of the Array drops the lookup to O(1), improving processing time to ~8ms (a ~15x speedup) while maintaining backward compatibility with `instanceof Map` checks.
