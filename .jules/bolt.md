## 2025-07-07 - Optimized course enrichment with O(1) user lookup
**Learning:** The `enrich` function was performing an $O(N)$ lookup using `Array.find` inside a loop over courses, leading to $O(C \times U)$ complexity. For 1,000 courses and 5,000 users, this took ~142ms.
**Action:** Convert the users array to a `Map` before the enrichment loop to achieve $O(C + U)$ complexity, reducing processing time to ~24ms (including Map creation) or ~1ms (Map lookup only).

## 2025-07-07 - Risk of stripping null bytes with `tr -d '\000'`
**Learning:** Using `tr -d '\000'` to "clean" a file for `grep` can corrupt valid control characters used in regexes (e.g., `[\000-\x1f]`). This led to a `SyntaxError` because the range became invalid.
**Action:** Avoid global null-byte stripping on source files. Use safer escape sequences like `\x00` in regexes to make them resilient to such tools, and always run `node -c` to check for syntax errors after modifications.
