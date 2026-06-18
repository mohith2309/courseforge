## 2025-05-14 - [CRITICAL] Entitlement spoofing and admin token leakage
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed users to grant themselves Pro status and claim paid courses without payment. Additionally, `isAdmin` accepted tokens in query parameters.
**Learning:** Client-provided state for entitlements (like `pro: true`) is a "trust but verify" anti-pattern; if the server doesn't re-validate the item's cost (e.g. `priceInr === 0`), it's vulnerable to spoofing. Admin tokens in URLs leak to logs and history.
**Prevention:** Always use the server as the source of truth for pricing and entitlements. Strip query parameter support for sensitive tokens; use headers and `timingSafeEqual` exclusively.
