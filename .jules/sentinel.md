## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-02 - Unauthorized Privilege Escalation and Course Claiming
**Vulnerability:** Client-asserted privilege escalation and unauthorized paid course claiming via unvalidated backend endpoints.
**Learning:** Authenticated endpoints that update user status or grant access to resources must not trust client-side assertions of entitlement. Relying on a "mock" flag for development without enforcing it as a gate for sensitive operations in the backend leads to trivial bypasses.
**Prevention:** Enforce server-side validation for all entitlement changes. Use development flags like `ALLOW_MOCK_PAYMENTS` to explicitly gate shortcuts and ensure they are disabled by default in production.
