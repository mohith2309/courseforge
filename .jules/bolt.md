
## 2024-05-24 - Optimize O(N^2) data enrichment via Maps
**Learning:** In list API endpoints (like `/courses/published`), calling `Array.find` within an `Array.map` (e.g., enriching courses with user data) scales as O(N * M) or O(N^2), causing huge performance degradation for large datasets.
**Action:** When decorating items with external associations in a loop, pre-build a `Map` (O(N) setup) for O(1) lookups during the main loop, turning the complexity to O(N + M). Use an `instanceof Map` check in the shared utility if it must maintain backward compatibility for other O(N) callers.
