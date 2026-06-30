## 2024-05-24 - Fail-Closed Initialization Check for Default Secrets
**Vulnerability:** The application allowed startup in production environments (`NODE_ENV=production`) while retaining weak, default configuration secrets (`admin-dev` for `ADMIN_TOKEN` and `dev-secret` for `JWT_SECRET`).
**Learning:** If these defaults are left unchanged during deployment, attackers can forge JWT tokens and trivially bypass administrative checks by providing the known default token.
**Prevention:** Implement a hard initialization check (`process.exit(1)`) immediately after loading environment variables. If `PROD` is true and either secret is set to its development default, forcibly prevent the application from starting.
