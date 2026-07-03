## 2024-05-18 - Prevent Denial of Service via crypto.timingSafeEqual
**Vulnerability:** The `crypto.timingSafeEqual` function throws an unhandled exception if the provided buffers have different byte lengths. The original code compared string `.length` before creating buffers, allowing multi-byte characters to match string length but differ in byte length, crashing the server.
**Learning:** Always validate `.byteLength` on `Buffer` objects or compare `Buffer.byteLength(string)` before passing them to `crypto.timingSafeEqual` in Node.js to avoid application crashes.
**Prevention:** In functions performing timing-safe comparisons (like `safeEq` or `verifyToken`), ensure strict pre-validation of byte length instead of string length.
