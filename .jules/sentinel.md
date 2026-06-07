## 2025-05-22 - Client-Side Entitlement Spoofing
**Vulnerability:** Authenticated users could self-grant "Pro" status by calling the insecure `POST /me/pro` endpoint or by passing `pro: true` to the `POST /me/claim` endpoint, which lacked server-side verification.
**Learning:** Entitlement logic was partially implemented on the server but still trusted client-provided flags for high-value status transitions.
**Prevention:** Remove all client-driven status escalation endpoints; entitlements must only be granted through verified server-side flows (e.g., payment verification or admin actions).
