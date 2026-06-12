## 2025-05-14 - Entitlement Spoofing and Admin Token Leakage

**Vulnerability:**
1. Unauthorized "Pro" status upgrade via `/me/pro` and `/me/claim` endpoints.
2. Arbitrary course claiming via `/me/claim`.
3. Admin token leakage through URL query parameters.

**Learning:**
1. The server trusted client-provided data for entitlements (`pro: true` in body) without verification.
2. The `/me/claim` endpoint lacked checks to ensure courses being claimed were actually free.
3. Supporting `adminToken` in URLs is a common but dangerous pattern that exposes secrets in logs and history.

**Prevention:**
1. Always verify entitlement changes server-side (e.g., check price, verify payment).
2. Remove "convenience" endpoints like `/me/pro` that bypass payment logic.
3. Only accept sensitive tokens (admin, bearer) via secure HTTP headers.
