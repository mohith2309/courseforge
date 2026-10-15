## 2024-06-03 - O(1) Map Lookups for Array Enrichment
**Learning:** When attaching relational data (e.g., users to courses) in loops, using `array.find()` inside `array.map()` results in O(N*C) complexity. This causes severe performance degradation as the data sets grow. Converting the relational array to a `Map` before mapping over the main array reduces the complexity to O(N+C) by enabling O(1) lookups.
**Action:** Always construct a `Map` for O(1) lookups before looping over lists to enrich them with relational data from another array.
