## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2024-07-07 - Fix privilege escalation and enforce fail-closed configuration
**Vulnerability:** A critical privilege escalation vulnerability existed in the `/me/claim` endpoint allowing any user to grant themselves Pro status by sending `{"pro": true}` in the request body. Additionally, the server would start in production with insecure defaults (e.g. `JWT_SECRET === 'dev-secret'`).
**Learning:** The `/me/claim` endpoint trusted the `pro` field from the client payload instead of securely validating payment or entitlement history. The lack of a startup security check allowed misconfigured instances to run silently.
**Prevention:** Always validate authorization or entitlement state server-side instead of trusting client inputs. Implement a fail-closed startup check in production to abort execution if critical security configurations are missing or left to their dev defaults.
