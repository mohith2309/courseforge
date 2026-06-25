## 2025-05-14 - Harden Authentication and Prevent Secret Leakage
**Vulnerability:**
1. `safeEq` crashed when comparing strings with matching character lengths but different byte lengths (multi-byte characters), leading to 500 errors.
2. `adminToken` was accepted via query parameter, risking secret leakage in server logs, browser history, and referer headers.
3. `/ai/` routes were open if `APP_KEY` was not configured.
4. Production environment could start with development default secrets.

**Learning:**
`crypto.timingSafeEqual` requires buffers of identical byte length. Linear string length checks are insufficient for multi-byte UTF-8 characters. Query parameters for secrets are inherently insecure due to logging and referral leakage.

**Prevention:**
1. Always convert strings to Buffers and compare `byteLength` before timing-safe comparison.
2. Enforce secret transmission via custom headers only.
3. Implement fail-closed gates for all sensitive proxy routes.
4. Explicitly verify that production environments do not use default development secrets at startup.
