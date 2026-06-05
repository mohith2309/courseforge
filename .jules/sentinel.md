## 2025-05-14 - [Fail-Open Security Gates]
**Vulnerability:** Several security checks (AI proxy gate, payment verification) were designed to "fail open" if configuration was missing or in a default state.
**Learning:** The AI proxy check `if (APP_KEY && !safeEq(...))` was skipped entirely if `APP_KEY` was not set, making the proxy wide open by default. Similarly, payment verification was bypassed if Razorpay keys were missing, even if mock payments were not explicitly allowed.
**Prevention:** Always implement "fail-closed" logic. Security checks should be mandatory, and the system should only allow bypasses if a specific, high-visibility debug flag (like `ALLOW_MOCK_PAYMENTS`) is explicitly set to true. Production mode (`PROD`) should further enforce these checks regardless of other configurations. When checking for keys, ensure explicit presence checks: `if (PROD && !APP_KEY) throw Error();`

## 2025-05-14 - [Empty String Equality Bypass]
**Vulnerability:** Logic like `if (gate || prod) && !safeEq(input, gate || '')` allows bypasses if `gate` is null and `prod` is true.
**Learning:** If `gate` is null, `gate || ''` resolves to an empty string. An attacker sending an empty input header will satisfy the equality check (`'' == ''`), bypassing the gate.
**Prevention:** Explicitly check for the presence of the secret key before performing equality checks, especially in production environments.
