## 2026-02-10 - [O(N) to O(1) enrichment lookup]
**Learning:** The catalog and admin endpoints were performing a linear search through the entire users array for every course being enriched. This created an $O(C \times U)$ complexity. Benchmark at 5,000 items showed latency drop from ~192ms to ~14ms by using a Map.
**Action:** Always use Map-based lookups when joining two datasets in-memory during request processing.
