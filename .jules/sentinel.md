## 2024-06-20 - Admin Token Leakage via URL Parameter
**Vulnerability:** The `isAdmin` check allowed the admin token to be passed via the `adminToken` URL query parameter as a fallback to the `x-admin-token` header.
**Learning:** Allowing sensitive tokens in URL parameters is a significant security risk because query strings are often logged in plain text by web servers, reverse proxies, and analytics tools. They can also leak via the `Referer` header to third-party sites and remain in browser histories.
**Prevention:** Always enforce strict header-based authentication (e.g., `Authorization: Bearer` or custom headers like `x-admin-token`) for sensitive API endpoints. Never fallback to reading credentials from the request URL.
