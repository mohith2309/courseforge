
## 2026-06-22 - Bulk Course Enrichment Bottleneck
**Learning:** Performing Array.find() inside a map() loop for bulk data enrichment creates an O(C * U) complexity bottleneck. Converting the lookup array into a Map once before the loop reduces complexity to O(C + U) with O(1) lookups.
**Action:** Use Map-based lookups for any bulk enrichment logic in the backend.
