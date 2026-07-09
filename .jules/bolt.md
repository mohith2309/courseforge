## 2026-07-09 - [O(N^2) Course Enrichment Bottleneck]
**Learning:** The course enrichment logic in the backend was performing an O(N) user lookup within an O(C) course loop, resulting in O(C*U) complexity. This significantly slows down the catalog and admin routes as the user base grows.
**Action:** Convert the user array to a Map for O(1) lookups before iterating over the course list to reduce complexity to O(C+U).
