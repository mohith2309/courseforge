## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-01 - Production Config Hardening and Privilege Escalation Fix
**Vulnerability:** Unauthorized privilege escalation via /me/pro and /me/claim endpoints, and insecure default configuration in production.
**Learning:** Endpoints intended for guest-to-account migration often bypass payment verification, creating a direct path for privilege escalation if not gated by strict environment flags.
**Prevention:** Gated simulated entitlement endpoints with a strict ALLOW_MOCK_PAYMENTS flag and implemented a fail-closed startup check that aborts if production runs with insecure defaults.
