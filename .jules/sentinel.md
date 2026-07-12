## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a security secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-12 - Strict Production Startup Checks and Privilege Escalation Mitigation
**Vulnerability:** Unauthorized privilege escalation via `/me/pro` and `/me/claim` endpoints when mock payments were implicitly enabled, and risk of running in production with default secrets.
**Learning:** Client-asserted state changes (like "claiming" a course) must be strictly gated by the same flags that control the payment mode (e.g., `ALLOW_MOCK_PAYMENTS`). Relying on environment variables being "set correctly" is not enough; the application should perform fail-closed checks at startup.
**Prevention:** Implement strict startup validation that aborts the process if insecure configurations (default secrets, enabled mock features) are detected in a production environment. Always gate client-driven state migrations behind feature flags that are disabled by default in production.
