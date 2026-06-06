## 2025-05-15 - [Security Pattern] Google ID token audience validation
**Vulnerability:** Google ID token audience validation using `.includes()` on the project number can allow unauthorized tokens to pass if their audience/client ID contains the project number as a substring.
**Learning:** Strict equality or exact hyphenated prefix matches are necessary to prevent substring-based bypasses.
**Prevention:** Always use exact matching or a strictly defined regex when validating token audiences or client IDs.
