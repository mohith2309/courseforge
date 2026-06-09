## 2025-05-23 - [AI Gate Fail-Open]
**Vulnerability:** AI endpoints were accessible without authentication if the mandatory 'APP_KEY' was missing from the environment.
**Learning:** The check 'if (APP_KEY && !safeEq(...))' explicitly allowed bypasses when 'APP_KEY' was undefined, which is a common failure pattern for optional-looking security gates.
**Prevention:** Always use 'fail-closed' logic by ensuring the presence of required security keys before validating them: 'if (!APP_KEY || !safeEq(...))'.
