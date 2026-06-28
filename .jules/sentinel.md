# Sentinel Security Journal

## 2025-05-15 - Denial of Service via Timing-Safe Equality
**Vulnerability:** Node.js `crypto.timingSafeEqual` throws an unhandled exception if the two input Buffers have different byte lengths. When used with user-provided strings (like tokens or API keys), an attacker can cause the server to crash by providing a value that, when converted to a Buffer, has a different byte length than the expected value (e.g., using multi-byte characters).

**Learning:** String `.length` is not a reliable check for Buffer `.byteLength` because multi-byte UTF-8 characters can result in different byte lengths for the same string length.

**Prevention:** Always convert both inputs to Buffers first, and explicitly compare their `.byteLength` before calling `crypto.timingSafeEqual`.

## 2025-05-15 - Admin Token Leakage via Query Parameters
**Vulnerability:** The `isAdmin` check allowed the `adminToken` to be passed via a URL query parameter.

**Learning:** URL parameters are often logged by web servers, proxies, and browser history. They can also be leaked via the `Referer` header when navigating to external sites. Sensitive tokens should only be passed in headers.

**Prevention:** Only accept administrative or sensitive tokens via custom headers (e.g., `x-admin-token`).
