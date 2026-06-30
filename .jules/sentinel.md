## 2025-05-14 - Denial of Service via crypto.timingSafeEqual Buffer Length Mismatch
**Vulnerability:** Input buffers to `crypto.timingSafeEqual` must have the exact same byte length, or the function will throw an unhandled exception, leading to a server crash (Denial of Service).
**Learning:** String length checks (e.g., `a.length !== b.length`) are insufficient in Node.js when multi-byte characters are involved, as `Buffer.from(string).byteLength` may differ from `string.length`.
**Prevention:** Always convert both strings to Buffers first and compare their `.byteLength` before calling `crypto.timingSafeEqual`.
