## 2026-06-06 - [O(n) to O(1) Lookup Optimization]
**Learning:** In the `enrich` function, performing an array search (`users.find`) inside a map loop over courses creates O(C*U) complexity. Converting the `users` array to a `Map` before the loop reduces this to O(C+U), which is significantly faster as the number of users and courses grows.
**Action:** Always check for nested loops that perform searches in arrays and consider using a `Map` or `Set` for O(1) lookups if the search key is unique.
