## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-02 - Gated privilege escalation and fail-closed production checks
**Vulnerability:** Privilege escalation in /me/pro and /me/claim endpoints allowing any user to assert Pro status or claim paid courses.
**Learning:** Development-friendly "shortcuts" or migration helpers can become critical security holes if left ungated in production.
**Prevention:** Gate all simulated or unverified state-changing logic behind a flag (e.g., ALLOW_MOCK_PAYMENTS) and implement a fail-closed startup check that prevents the server from running in production with insecure defaults or mock flags enabled.
