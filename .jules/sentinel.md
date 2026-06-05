# Sentinel Security Journal

## 2026-06-05 - [Fail-Open Vulnerabilities in AI and Payment Gates]
**Vulnerability:** The server implemented security gates that defaulted to "allow" if configuration was missing. AI endpoints allowed any request if `APP_KEY` was not set, and payment verification allowed mock payments/bypass if `RZP_LIVE` was false or `ALLOW_MOCK_PAYMENTS` was true, even in potential production scenarios.
**Learning:** Checking for the existence of a key before enforcing it (e.g., `if (KEY && !verify(KEY))`) creates a "fail-open" state where missing configuration leads to a total security bypass.
**Prevention:** Always implement "fail-closed" logic: `if (!KEY || !verify(KEY)) deny()`. Ensure that critical production checks (like payment signatures) cannot be bypassed by environment variables or missing keys when `NODE_ENV === 'production'`.
