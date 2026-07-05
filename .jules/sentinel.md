## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-05 - Fail-closed startup check for production secrets
**Vulnerability:** Application remains operational in production with development-default secrets (JWT_SECRET and ADMIN_TOKEN), enabling trivial token forgery and administrative bypass.
**Learning:** Reliance on per-request checks or environment documentation is insufficient to prevent misconfiguration. A fatal startup check is the only way to guarantee a secure production state.
**Prevention:** Implement a global fail-closed check at the entry point that validates critical security environment variables against known insecure defaults specifically when NODE_ENV=production.
