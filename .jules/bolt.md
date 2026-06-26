## 2026-06-26 - Bulk course enrichment optimization
**Learning:** Bulk enrichment of courses (joining courses with user publisher data) had O(C * U) complexity due to nested Array.find lookups. This caused significant latency as the number of courses and users grew.
**Action:** Use a Map for O(1) lookups during bulk operations. Pre-instantiate the Map once per request to reduce complexity to O(C + U). Maintain fallback in the enrichment function for single-item lookups or non-optimized callers.
