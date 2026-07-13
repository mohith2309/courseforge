## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2025-05-15 - Client-Asserted Privilege Escalation
**Vulnerability:** The /me/pro and /me/claim endpoints implicitly trusted client requests to grant Pro status and paid courses without verifying actual payments or receipts.
**Learning:** Client-side guest-to-authenticated migrations that rely on self-asserted state can easily lead to privilege escalation if not explicitly gated or verified on the backend.
**Prevention:** Always gate migration flows that rely on client-asserted state behind a feature flag like ALLOW_MOCK_PAYMENTS or strictly validate against real receipts.
