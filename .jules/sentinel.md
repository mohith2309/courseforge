## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-06 - Fail-closed startup logic for production secrets
**Vulnerability:** The server could be started in production (`NODE_ENV=production`) using weak default secrets (`admin-dev` for `ADMIN_TOKEN` and `dev-secret` for `JWT_SECRET`) or with mock payments enabled (`ALLOW_MOCK_PAYMENTS=true`), leading to complete authorization bypass and false payments.
**Learning:** Default configuration values are necessary for easy local development but become critical vulnerabilities if they leak into production. Relying solely on environment variable configuration without active runtime validation is insufficient.
**Prevention:** Implement a strict fail-closed check at application startup that evaluates critical configuration state when running in production, using `process.exit(1)` to abort initialization if vulnerable settings are detected.
