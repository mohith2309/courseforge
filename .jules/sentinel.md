## 2024-05-30 - Client-Asserted Privilege Escalation

**Vulnerability:** The `/me/pro` and `/me/claim` endpoints allowed any authenticated user to arbitrarily grant themselves Pro status or claim ownership of courses without verifying any payment receipt.

**Learning:** Trusting client-asserted purchase state (e.g., from a guest-to-authenticated migration flow) without server-side validation of the actual payment receipt is a critical security risk leading to privilege escalation.

**Prevention:** Ensure that state-mutating endpoints related to entitlements are strictly validated against real receipts or explicitly gated by server-side feature flags (like `ALLOW_MOCK_PAYMENTS`) that are disabled in production.
