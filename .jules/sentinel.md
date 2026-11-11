## 2026-11-11 - Prevent Privilege Escalation in /me/pro and /me/claim
 **Vulnerability:** Unauthenticated/guest privilege escalation allowing users to claim Pro status and paid courses without valid purchase validation.
 **Learning:** Client-asserted purchases or status changes without receipt validation or feature flagging allow malicious actors to spoof requests and gain unauthorized access to premium features in production.
 **Prevention:** Ensure all entitlement-granting endpoints either strictly validate external purchase receipts or are explicitly disabled/gated in production using robust feature flags (e.g., ALLOW_MOCK_PAYMENTS) before processing any status changes.
