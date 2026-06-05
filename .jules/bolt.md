## 2025-05-15 - O(1) publisher lookup for course enrichment
**Learning:** In the course enrichment process, using `Array.find` inside a loop results in O(C*U) complexity. Replacing the user array with a pre-indexed `Map` reduces this to O(C+U).
**Action:** Always pre-index lookup arrays into Maps/Objects when performing multiple lookups within a loop or across a large collection.
