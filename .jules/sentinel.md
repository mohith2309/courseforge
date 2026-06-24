## 2024-11-28 - Timing-Safe Comparison Crash on Multi-byte Characters
**Vulnerability:** The `safeEq` function compared string lengths before passing strings to `crypto.timingSafeEqual()` using `Buffer.from()`. Since `Buffer.from()` expands multi-byte strings to larger byte lengths, an attacker passing a multi-byte string (e.g. via `x-admin-token`) matching the character length of the true secret could bypass the length check and crash the application because `timingSafeEqual` throws when buffer lengths differ.
**Learning:** Comparing character lengths (`.length` on a string) does not correlate safely to byte lengths when using `Buffer.from()`. This mismatch allows unhandled exceptions to take down the server process when comparing secrets.
**Prevention:** Always convert strings to buffers *first*, and then compare `.length` on the buffers before passing them to `crypto.timingSafeEqual()`.

## 2024-11-28 - Insecure Admin Token Fallback
**Vulnerability:** The `isAdmin` gate permitted passing the `adminToken` via a URL query parameter.
**Learning:** Secrets sent via URL query parameters are logged in access logs, proxy logs, and are passed in Referer headers, leading to potential leakage.
**Prevention:** Strictly enforce secret passing via custom headers (e.g., `x-admin-token`) or the Authorization header.
