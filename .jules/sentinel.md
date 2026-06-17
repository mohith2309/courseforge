## 2025-06-17 - Insecure Pro escalation and entitlement spoofing
**Vulnerability:** The `/me/pro` endpoint allowed any authenticated user to grant themselves Pro status without payment. Additionally, the `/me/claim` endpoint allowed users to claim any course ID (even paid ones) and self-assign Pro status via the request body.
**Learning:** Entitlements and premium status were partially trusted to the client-side request parameters, violating the "trust nothing from the client" principle.
**Prevention:** Always validate entitlements and status changes on the server against the source of truth (e.g., payment records or course price). Remove convenience endpoints that bypass security checks.
