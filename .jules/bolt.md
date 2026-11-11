## 2026-07-02 - Course enrichment Map lookup optimization
**Learning:** In endpoint routes listing courses (`/courses/published` and `/admin/pending`), enriching course items with publisher information by repeatedly running `users.find()` over an array created an O(N * M) nested scan.
**Action:** Pre-index lookup entities (like users) into a `Map` so each lookup is O(1), bringing total enrichment time down from O(N * M) to O(N + M) while retaining backward compatibility by accepting either `Map` or `Array` in helper functions.
