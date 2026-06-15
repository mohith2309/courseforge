## 2025-05-15 - [Fail-Closed Security & Strict Audience Validation]
**Vulnerability:** The AI proxy and payment verification were potentially "fail-open" in production if environment keys were missing. Additionally, Google ID token audience validation used a loose `.includes()` check.
**Learning:** Security gates must explicitly check for production environment status and mandatory configuration to prevent bypasses in misconfigured deployments. Audience validation for OAuth tokens must be strict to prevent cross-project token reuse.
**Prevention:** Always implement "fail-closed" logic for critical gates (`if (PROD && !KEY) return error`). Use exact matching or strict prefix matching for ID token audience fields.
