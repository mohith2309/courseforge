## 2025-05-15 - Stricter Google ID Token Audience Validation
**Vulnerability:** Google ID token audience (`aud`) and authorized party (`azp`) were validated using `.includes(FIREBASE_PROJECT_NUM)`.
**Learning:** Using `.includes()` for project number validation allows potential substring collision bypasses where a token from a different project could be accepted if its ID contains the target project number.
**Prevention:** Always use strict equality or precise prefix matching (e.g., `startsWith(PROJECT_NUM + '-')`) for OAuth audience and client ID checks.

## 2025-05-15 - Sensitive Token Exposure in URL Parameters
**Vulnerability:** Admin authentication allowed passing the `adminToken` via a URL query parameter.
**Learning:** URL query parameters are frequently logged by web servers, proxies, and browser history, leading to accidental exposure of sensitive credentials.
**Prevention:** Pass authentication tokens exclusively via HTTP headers (e.g., `Authorization` or custom `x-*` headers) and ensure they are not accepted from query parameters.
