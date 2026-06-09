# Bolt's Journal - Performance Learnings

## 2025-05-15 - [Initial Setup]
**Learning:** Performance optimizations should target measurable improvements and remain under 50 lines. Map-based lookups and Set-based membership checks are high-value targets in this codebase.
**Action:** Prioritize O(1) lookups in hot paths and avoid redundant collection allocations.
