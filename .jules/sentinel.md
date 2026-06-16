## 2026-06-16 - Entitlement Spoofing via Unvalidated Claims
**Vulnerability:** The `/me/claim` endpoint allowed users to attach any course ID to their account without verifying the course's price or status, effectively bypassing the payment gateway for premium content.
**Learning:** Client-side "claims" for guest-to-account migration must be strictly validated on the server. Never trust the client to tell you what they "already have" unless it can be verified against a source of truth (like checking if the course is actually free).
**Prevention:** Implement server-side verification for all entitlement-granting endpoints. For migrations, only allow claiming items that are universally free.

## 2026-06-16 - Server Crash on Timing-Safe Comparison Length Mismatch
**Vulnerability:** The `safeEq` utility used `crypto.timingSafeEqual` which throws an error in Node.js if the input buffers have different lengths.
**Learning:** Hardening authentication (e.g., restricting tokens to headers) increases the surface area for this crash if attackers provide malformed headers. Timing-safe equality checks MUST always be preceded by a length check to prevent an easy Denial-of-Service (DoS) vector.
**Prevention:** Always use a length-checking wrapper around `crypto.timingSafeEqual`: `if (a.length !== b.length) return false; return crypto.timingSafeEqual(a, b);`.
