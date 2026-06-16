## 2025-06-06 - [Insecure Trust in Client for Premium Status]
**Vulnerability:** The server allowed any authenticated user to grant themselves "Pro" status by sending a POST request to `/me/pro` or by including `pro: true` in a `/me/claim` request, without any payment verification.
**Learning:** Authenticated endpoints that modify user entitlements must verify the underlying authority (e.g., a payment signature or an admin action) rather than trusting client-provided flags.
**Prevention:** Remove debug or unverified entitlement-granting endpoints from production code. Always verify payments server-side before updating user status.
