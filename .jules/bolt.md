## 2025-05-15 - Optimized Course Enrichment with Map Lookups
**Learning:** In routes like `/courses/published` and `/admin/pending`, enlisting courses involved an O(N * M) operation where N is the number of courses and M is the number of users. By converting the user list to a Map for O(1) lookups once per request, the complexity was reduced to O(N + M).
**Action:** Always prefer Map-based lookups when joining two datasets in-memory during a request.
