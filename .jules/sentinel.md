## 2025-05-14 - Entitlement Spoofing and Admin Token Leakage
**Vulnerability:** Insecure endpoints (/me/pro and /me/claim) allowed clients to self-grant "Pro" status and claim paid courses without server-side verification. Additionally, the admin token was accepted as a query parameter, risking leakage in logs and history.
**Learning:** Trusting the client for authorization status or price validation is a critical vulnerability. Claims must always be verified against the source of truth (the database).
**Prevention:** Remove insecure "set" endpoints that lack strict server-side validation. Enforce that sensitive tokens (like admin tokens) are only accepted via secure headers, never via URLs.
