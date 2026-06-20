## 2025-05-15 - Fix adminToken regression
**Vulnerability:** Admin authentication allowed the `adminToken` to be passed via a URL query parameter, which could lead to token leakage in server logs, browser history, and HTTP referer headers.
**Learning:** A previous security fix to remove query parameter authentication had regressed. Security gates must be fail-closed and strictly enforced via secure channels (headers) to prevent accidental re-introduction of vulnerabilities.
**Prevention:** Always prefer custom headers (e.g., `x-admin-token`) for sensitive tokens. Implement automated security regression tests that specifically check for the absence of insecure authentication methods.
