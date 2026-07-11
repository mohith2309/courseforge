## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2026-07-11 - Privilege Escalation in /me/pro and /me/claim
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed any authenticated user to grant themselves "Pro" status and claim paid courses without actual payment verification, bypassing the mock payments check.
**Learning:** Guest-to-authenticated migration flows (like claiming local purchases) are highly susceptible to parameter tampering. If a client can arbitrarily assert purchase state to the backend, it leads to direct privilege escalation. The migration flow must be gated by the same mock payment flag as the main payment flow, or otherwise strictly validated against real receipts.
**Prevention:** Ensure that state-mutating endpoints, especially those granting paid entitlements, enforce server-side validation of the transaction or restrict usage via feature flags (e.g., `ALLOW_MOCK_PAYMENTS`) before trusting client assertions.
