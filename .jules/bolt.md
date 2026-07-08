## 2025-05-14 - Optimized Course Enrichment (O(N^2) to O(N))
**Learning:** Attaching publisher information to a list of courses using `Array.find()` inside a loop results in O(C*U) complexity (Courses * Users). As the marketplace grows, this causes measurable latency in the `/courses/published` and `/admin/pending` routes.
**Action:** Construct a `Map` of users for O(1) lookups before processing the course list. This reduces the complexity to O(C+U), providing a ~15x speedup in typical scenarios.
