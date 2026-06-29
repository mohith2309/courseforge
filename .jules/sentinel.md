## 2025-05-15 - TimingSafeEqual DoS Vulnerability
**Vulnerability:** Node.js `crypto.timingSafeEqual` throws an unhandled exception if the input Buffers have different byte lengths. If string lengths are used for a preliminary check, multi-byte characters can cause a mismatch between string length and byte length, leading to a server crash (DoS).
**Learning:** Always compare `.byteLength` of Buffers created from strings before calling `timingSafeEqual`. String `.length` is not a reliable indicator of byte length for non-ASCII characters.
**Prevention:** Use a robust equality helper that converts both inputs to Buffers and explicitly checks `byteLength` before performing the timing-safe comparison.
