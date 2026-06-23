## 2026-06-23 - Hardened Security Gates and Production Secret Enforcement
**Vulnerability:** Admin tokens could be passed via URL query parameters, risking leakage in server logs and referer headers. AI endpoints had a fail-open gate if `APP_KEY` was missing from the environment.
**Learning:** Security gates that fallback to a permissive state when configuration is missing (fail-open) are dangerous. Using URL parameters for sensitive tokens is a common but high-risk pattern.
**Prevention:** Always implement fail-closed logic (explicitly deny access if config is missing). Strictly enforce custom headers for tokens and abort production startup if default secrets are detected.
