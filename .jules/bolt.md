## 2025-05-18 - Optimize enrich array lookups
**Learning:** Using Array.find for lookups inside a map over arrays (N*M) can be slow on larger datasets. Map lookups are O(1) and improve throughput significantly (from ~373ms to ~9ms).
**Action:** When enriching arrays of objects with data from other arrays, build a Map for lookups beforehand to reduce time complexity to O(N + M).
