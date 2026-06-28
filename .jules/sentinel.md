## 2024-05-24 - [CRITICAL] DoS via timingSafeEqual and Token Leakage
**Vulnerability:**
1. `crypto.timingSafeEqual` throws an unhandled exception (crashing the server) if the input Buffers have different byte lengths. Previously, the code checked `.length` on strings before converting to Buffers, which is insufficient because a multi-byte character (e.g., 'ä') has a string length of 1 but a byte length of 2 or more. This allows a remote attacker to crash the server (DoS) by sending a payload with multi-byte characters that matches the expected string length but not the byte length.
2. The `isAdmin` function fell back to reading the admin token from the URL query parameter (`adminToken`). This exposes the highly sensitive token in server access logs, browser history, and HTTP referer headers.

**Learning:**
1. `crypto.timingSafeEqual` strict byte length requirements apply to the *Buffer's* byte length, not the original string's length. Always convert to Buffers first and check `.byteLength`.
2. Sensitive tokens (like admin keys) must never be passed via URL query parameters. Always prefer custom headers (e.g., `x-admin-token`).

**Prevention:**
1. In `verifyToken` and `safeEq`, explicitly convert inputs to `Buffer` (or use `Buffer.byteLength`) and check `.byteLength` equality before calling `crypto.timingSafeEqual`.
2. Remove the URL query parameter fallback (`url.searchParams.get('adminToken')`) from the `isAdmin` check, strictly enforcing header-based authentication.
