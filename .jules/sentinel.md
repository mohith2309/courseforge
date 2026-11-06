## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2023-10-27 - Fail-fast on weak configuration in production
**Vulnerability:** Weak default tokens and mock flags active in production.
**Learning:** Checking for insecure configurations late in code (e.g., inside an admin route handler) is insufficient because it leaves other parts of the system exposed to weak tokens (like JWT).
**Prevention:** Implement a strict fail-closed check at startup that halts the server (`process.exit(1)`) if weak defaults (e.g., `ADMIN_TOKEN`, `JWT_SECRET`) or risky flags (`ALLOW_MOCK_PAYMENTS`) are detected in production.
