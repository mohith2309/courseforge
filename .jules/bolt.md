## 2025-02-18 - Optimized O(N^2) Array Enrichment Loop
**Learning:** Decorating items in an array by calling `.find()` on another array inside a `.map()` loop leads to an O(N * M) performance bottleneck (effectively O(N^2) if lists scale together). In JS, this gets very slow once user and course lists grow.
**Action:** Always convert the secondary lookup array into a `Map` prior to iterating. This shifts the complexity to O(N + M) and yields a massive performance improvement. Make the helper (`enrich`) accept `users instanceof Map` to retain backward compatibility.
