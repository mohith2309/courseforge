## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-02 - Privilege Escalation and IDOR in Entitlements
**Vulnerability:** Authenticated users could grant themselves "Pro" status via the unvalidated `/me/pro` endpoint or the `pro` field in `/me/claim`. They could also claim any course ID via `/me/claim` without proof of payment.
**Learning:** Relying on client-side state or unvalidated POST requests for sensitive privilege changes is a major risk. Entitlements must be strictly managed by the server based on verified events (like successful payments).
**Prevention:** Remove any endpoints that grant privileges without server-side verification. In "claim" or "sync" operations, always validate the source of truth (e.g., check that the course is actually free or cross-reference with a verified purchase ledger).
