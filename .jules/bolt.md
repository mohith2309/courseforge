## 2024-05-24 - Array vs Map in Bulk Enrichment
**Learning:** Using `Array.find()` inside a loop (like `.map()`) creates O(C * U) complexity, which leads to significant latency spikes when processing large datasets, such as returning lists of courses.
**Action:** When a bulk enrichment process involves looking up related data from another list (like fetching publisher details for courses), always convert the lookup array into a `Map` *before* the loop. This reduces the complexity to O(C + U) with O(1) lookups inside the loop, preventing extreme latency degradation as the dataset grows.
