## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2026-07-01 - Prevent Misconfigured Default Secrets in Production
**Vulnerability:** Default values for `JWT_SECRET`, `ADMIN_TOKEN`, and `ALLOW_MOCK_PAYMENTS` were allowed in production, risking complete system compromise if left unchanged.
**Learning:** Hardcoded or fallback dev secrets are extremely dangerous if they accidentally slip into a production deployment, especially since they bypass authentication and billing logic.
**Prevention:** Implement strict fail-closed checks during application startup (`if (PROD) { ... process.exit(1) }`) to immediately halt execution if sensitive configurations are left at insecure default values.
