## 2026-06-28 - [Optimized Course Enrichment]
**Learning:** The `enrich` function was performing a linear search ((U)$) for the publisher of every course, leading to (C \times U)$ complexity in bulk endpoints like `/courses/published`.
**Action:** Use a `Map` to pre-hash users by ID ((U)$) before processing courses, reducing bulk enrichment complexity to (C + U)$. Implement a runtime check (`users instanceof Map`) in the helper function to maintain backward compatibility while allowing progressive optimization of route handlers.
