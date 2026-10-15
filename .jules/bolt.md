## 2026-02-09 - [Optimizing active tracking with Set]
**Learning:** Storing tracking data (like `activeDays` for streaks) as a `List` in Flutter state causes performance degradation in two ways: O(n) membership checks in update methods and frequent O(n) allocations in UI-triggered getters (via `toSet()`). Benchmarking showed a ~450x speedup when using a `Set` directly for 1,000 items.
**Action:** Always prefer `Set` over `List` for state properties that represent unique collections and are frequently checked for membership or used in derived computations in getters.
