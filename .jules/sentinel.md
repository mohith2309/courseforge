## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-02 - Fail-closed production secrets and defensive headers
**Vulnerability:** Use of development defaults for ADMIN_TOKEN and JWT_SECRET in production environments.
**Learning:** Relying on runtime checks inside specific routes for security is fragile. A global fail-closed check at startup ensures the environment is secure before any request is processed.
**Prevention:** Implement startup validation for all security-critical environment variables. Use restrictive CSP and Referrer-Policy headers even on JSON APIs to provide defense-in-depth against browser-side exploits.
