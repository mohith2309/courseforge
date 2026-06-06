## 2025-01-24 - Google ID Token Audience Confusion
**Vulnerability:** Google ID token audience validation used `.includes()` with a numeric project ID. This allowed tokens from other projects to be accepted if their client ID happened to contain the project ID as a substring (e.g., `1374206849691-abc...` would be accepted for project `374206849691`).
**Learning:** Google client IDs are usually in the format `project_number-random_string.apps.googleusercontent.com`. Relying on simple substring matches for numeric project IDs is dangerous because they can easily appear within larger numbers or as part of other client IDs.
**Prevention:** Always use exact matching or strict hyphenated prefix checks (`===` or `.startsWith(id + "-")`) when validating Google ID token audiences.
