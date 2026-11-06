## 2025-05-15 - Enforce secure configuration in production
 **Vulnerability:** Hardcoded default secrets (JWT_SECRET, ADMIN_TOKEN) and insecure flags (ALLOW_MOCK_PAYMENTS) allowed app startup in production.
 **Learning:** Without explicit fail-closed checks, missing environment variables can lead to silent fallback to default, insecure values, enabling token forgery and privilege escalation.
 **Prevention:** Always implement explicit, fail-closed startup checks that abort the process (`process.exit(1)`) if default or insecure configurations are detected in production environments.
