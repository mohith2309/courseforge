## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2024-05-24 - Privilege Escalation in /me/pro and /me/claim
**Vulnerability:** The `/me/pro` endpoint allowed any authenticated user to grant themselves "Pro" status simply by sending a POST request. Similarly, the `/me/claim` endpoint blindly accepted a `pro: true` parameter and any list of `courseIds` to grant ownership without verifying if the courses were actually free or purchased.
**Learning:** Client-side assertions of entitlements or payments should never be trusted. The backend must be the source of truth and verify payment receipts or free-tier eligibility before granting access.
**Prevention:** Remove endpoints that rely on client-asserted state. Ensure backend endpoints validate the status of resources (e.g., checking if a course is free `priceInr === 0`) before granting access, and rely on secure payment webhooks/verification for paid features.
