## 2025-05-14 - Timing Safe Equality Denial of Service
**Vulnerability:** A Denial of Service (DoS) vulnerability existed in the `safeEq` and `verifyToken` functions where multi-byte characters in inputs (like "©") could cause `crypto.timingSafeEqual` to throw an unhandled `RangeError` due to length mismatch, crashing the entire Node.js process.
**Learning:** Node.js's `crypto.timingSafeEqual` requires buffers of identical byte length. String `.length` only counts code units and is insufficient for pre-validation when multi-byte UTF-8 characters are involved.
**Prevention:** Always convert strings to Buffers and compare their `.byteLength` before calling `crypto.timingSafeEqual`.

## 2025-05-14 - Fail-Closed Production Defaults
**Vulnerability:** The application would start in production mode using development-only default secrets for `JWT_SECRET` and `ADMIN_TOKEN`, making it trivial to forge tokens or access administrative endpoints in deployed environments.
**Learning:** Default values in `cfg()` helpers are convenient for development but dangerous for production.
**Prevention:** Implement explicit, fail-closed checks at application startup that verify critical security environment variables are not set to known development defaults when `NODE_ENV=production`.
