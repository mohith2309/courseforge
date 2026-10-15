## 2024-05-18 - Optimize bulk course enrichment to O(C+U)
**Learning:** Performing `Array.find()` inside a `map()` loop (e.g., enriching a list of courses with user data) creates an $O(C \times U)$ complexity bottleneck. In this codebase, `server/server.js` was hitting this when rendering the catalog or admin lists.
**Action:** Convert the lookup array into a `Map` before the loop and pass the Map to the enrichment function, reducing the complexity to $O(C + U)$ with $O(1)$ lookups. The `enrich` function now uses `users instanceof Map` to seamlessly support both Array and Map inputs.
