## 2026-07-03 - timingSafeEqual crash on multi-byte characters
**Vulnerability:** Denial of Service (DoS) and potential timing oracle via `crypto.timingSafeEqual`.
**Learning:** In Node.js, `crypto.timingSafeEqual` throws an unhandled exception if the input buffers have different byte lengths. Using string `.length` for pre-validation is insufficient for multi-byte characters (e.g., Unicode), allowing an attacker to crash the server by providing a payload with matching string length but different byte length.
**Prevention:** Always compare `.byteLength` on the Buffers immediately before calling `crypto.timingSafeEqual`.
