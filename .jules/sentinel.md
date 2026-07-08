## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.

## 2026-07-01 - Trusting Client-Side Claims (Privilege Escalation)
**Vulnerability:** Broken Access Control / Privilege Escalation. The backend trusted client-provided requests to grant "Pro" status and claim course ownership without independent verification.
**Learning:** Never trust the client to dictate sensitive user state or entitlements. Logic like `if (body.pro === true)` or unvalidated course "claims" allows attackers to bypass payment flows.
**Prevention:** All state transitions and entitlement grants must be verified server-side against an authoritative source (e.g., a verified payment record). Guest-to-account migration should only allow claiming assets that were actually free when they were "acquired".
