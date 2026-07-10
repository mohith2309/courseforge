## 2026-07-01 - Fail-closed AI gate and DoS mitigation
**Vulnerability:** Fail-open AI route gate when APP_KEY is missing, and potential DoS crash in timingSafeEqual with multi-byte characters.
**Learning:** Defaulting to 'authorized' when a secret is missing is a common but dangerous pattern. Also, `crypto.timingSafeEqual` in Node.js throws if Buffer lengths differ, making length checks mandatory and sensitive to multi-byte characters if using string `.length`.
**Prevention:** Always implement fail-closed logic for security gates. Use `Buffer.byteLength` for pre-validation before cryptographic comparisons.
## 2024-07-10 - Unauthenticated Privilege Escalation / Claim Vulnerability in `/me/pro` and `/me/claim`
**Vulnerability:** The `/me/pro` and `/me/claim` endpoints lacked adequate production guards. This allowed arbitrary users to claim any courses (even paid ones) and to give themselves "Pro" status bypassing payments when `ALLOW_MOCK_PAYMENTS` is false.
**Learning:** Guest-to-authenticated migration flows and dev-centric shortcuts (like unlocking pro without a receipt) can act as unauthorized privilege escalation vectors if not explicitly restricted when production safeguards are active.
**Prevention:** Always gate dev-centric escalation routes or client-asserted purchase claims with robust checks against server-side configurations (like `ALLOW_MOCK_PAYMENTS`) and validate assertions against server-side source-of-truth.
