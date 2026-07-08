## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-08 - Fail-Closed Initialization on Default Secrets
**Vulnerability:** Starting the server in a production environment with default development secrets (like `dev-secret` or `admin-dev`) or with mock payments enabled.
**Learning:** Hardcoded fallback values for secrets are dangerous because if environment variables fail to load in production, the application will silently fall back to these easily guessable defaults, creating a critical authentication bypass.
**Prevention:** Implement a strict fail-closed check at application startup. If running in a production environment, verify that critical secrets do not match their default development values and immediately abort (`process.exit(1)`) if they do.
