## 2025-05-14 - [Insecure Claims & Privilege Escalation]
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed users to self-assign "Pro" status and claim paid courses without authorization or payment verification. Additionally, `isAdmin` accepted sensitive tokens in URL query parameters.
**Learning:** Client-provided flags (like `pro: true`) and course IDs in migration/claim endpoints must be validated against server-side truth (e.g., price checks) to prevent spoofing. Admin tokens should never be accepted in URLs to avoid leakage in logs/history.
**Prevention:** Remove self-service privilege escalation endpoints. Implement server-side verification for all entitlements. Restrict sensitive tokens to HTTP headers only.
