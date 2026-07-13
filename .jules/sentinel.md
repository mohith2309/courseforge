## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2025-05-22 - Secure production defaults and endpoint gating
**Vulnerability:** Privilege escalation via unprotected mock payment endpoints (/me/pro, /me/claim) and insecure default secrets in production.
**Learning:** Features intended for development (mock payments) can easily leak into production if not explicitly gated by environment-aware flags. Relying on "dev-secret" defaults for JWT and Admin tokens is a major risk.
**Prevention:** Implement a strict fail-closed startup check that aborts the process in production if insecure defaults or debug flags are active. Use feature flags (e.g., ALLOW_MOCK_PAYMENTS) to explicitly enable/disable dev-only routes.
