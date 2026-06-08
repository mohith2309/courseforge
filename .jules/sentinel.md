## 2025-05-22 - [Pro and Course Entitlement Bypass]
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed users to self-authorize premium status and course ownership without verification.
**Learning:** Entitlements were trust-on-client, assuming the client would only call these after successful local payment confirmation.
**Prevention:** Always verify payments server-side before granting entitlements. Remove "convenience" endpoints that skip verification.
