# Bolt's Journal - Performance Learnings

## 2025-05-15 - [Optimize course enrichment with O(1) user lookups]
**Learning:** In routes that return a list of courses enriched with publisher details, the `enrich` function was performing an O(N) linear search through the users array for every course. This leads to O(C*U) complexity where C is the number of courses and U is the number of users. Switching to a `Map` for user lookups reduces this to O(C+U).
**Action:** Always prefer Map lookups for cross-referencing datasets in list processing.
