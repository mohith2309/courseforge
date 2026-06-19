## 2025-05-15 - Hardening Entitlements, Admin Auth, and AI Gate

**Vulnerability:**
1. Entitlement spoofing via `/me/claim` (unvalidated course IDs and 'pro' flag) and `/me/pro` (unrestricted).
2. Admin token leakage via query parameters.
3. AI gate fail-open when `APP_KEY` environment variable was missing.

**Learning:**
1. Client-provided signals for entitlements (like 'pro: true') must never be trusted.
2. Sensitive tokens in URLs (query params) are exposed in logs and browser history.
3. Security gates must fail-closed; the absence of a configuration (like `APP_KEY`) should result in denied access, not allowed access.

**Prevention:**
1. Always validate entitlement claims against server-side truth (e.g., check `priceInr === 0` for free claims).
2. Restrict sensitive tokens to custom headers (e.g., `x-admin-token`).
3. Use strict conditional checks for security gates: `if (!KEY || KEY !== PROVIDED) return 401`.
