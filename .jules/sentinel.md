## 2024-05-18 - Google ID Token Substring Collision Auth Bypass
**Vulnerability:** The `/auth/exchange` endpoint used `.includes(FIREBASE_PROJECT_NUM)` to validate the `aud` and `azp` fields of Google ID tokens.
**Learning:** Using `.includes` for audience validation introduces a substring collision vulnerability. An attacker could register an OAuth client ID that happens to contain the target project's number (e.g., `123374206849691-malicious.apps.googleusercontent.com` matching `374206849691`). This allows tokens minted by the attacker's app to bypass validation, leading to complete authentication bypass for any user.
**Prevention:** Always use strict prefix matching (`startsWith(PROJECT_NUM + '-')`) or exact equality when validating token audiences to prevent substring injection bypasses.

## 2024-05-18 - Payment Verification Replay Attack
**Vulnerability:** The `/payments/verify` endpoint lacked an idempotency check, allowing re-use of the same valid Razorpay signature and `orderId` to trigger fulfillment multiple times.
**Learning:** Signature verification proves the payload is authentic but does not prevent replay attacks. Replaying the request indefinitely incremented course enrollment statistics and creator earnings.
**Prevention:** Implement strict state-based idempotency checks. Ensure that the unique transaction identifier (`orderId`) does not already exist in the `purchases` datastore before executing business logic.
