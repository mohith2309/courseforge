## 2026-06-27 - Denial of Service in Timing-Safe Comparison
**Vulnerability:** Node.js `crypto.timingSafeEqual` throws an unhandled `ERR_CRYPTO_TIMING_SAFE_EQUAL_LENGTH` exception if the input Buffers have different byte lengths. This can be exploited to crash the server (DoS) by providing input that matches the target's string length but differs in byte length (e.g., using multi-byte characters like emojis).
**Learning:** Checking `.length` on strings is insufficient for security comparisons involving multi-byte characters because `Buffer.from(string).byteLength` may differ from `string.length`.
**Prevention:** Always convert strings to Buffers and explicitly verify that `a.byteLength === b.byteLength` before calling `crypto.timingSafeEqual(a, b)`.
