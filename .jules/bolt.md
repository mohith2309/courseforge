## 2026-07-02 - Course Enrichment Optimization
**Learning:** Attaching user metadata to a large list of courses using `Array.find()` creates an O(N*M) bottleneck. Converting the user list to a `Map` before processing reduces this to O(N+M).
**Action:** Use a `Map` for lookups when decorating arrays of objects with data from another collection.
