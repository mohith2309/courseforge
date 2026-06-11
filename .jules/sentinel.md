## 2026-06-11 - [Insecure "Claim" Endpoints for Entitlements]
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed users to self-assign Pro status and paid courses without verification.
**Learning:** "Claim" or "sync" endpoints used during guest-to-account migration are high-risk for entitlement spoofing if they trust the client to specify what content it should "own".
**Prevention:** Always verify on the server that claimed content is actually free (e.g., `priceInr === 0`). Never allow clients to directly toggle premium status via simple POST requests without proof of payment or administrative action.
