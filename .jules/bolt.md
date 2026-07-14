## 2025-05-15 - Optimize course enrichment with Map lookup
**Learning:** In routes that return lists of courses (published/pending), looking up the publisher for each course using `Array.find` leads to O(N * M) complexity. Using a `Map` for O(1) lookups reduces this to O(N + M).
**Action:** Always prefer Map-based lookups when enriching collections from another reference collection.
