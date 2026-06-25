## 2026-06-25 - Enforce fail-closed and remove token leakage
**Vulnerability:** Default secrets allowed in production; admin token leaked via URL query params.
**Learning:** Fail-closed design must be enforced at application initialization; sensitive tokens should never be passed via URL.
**Prevention:** Abort startup if production environment uses default secrets; only accept tokens via headers.
