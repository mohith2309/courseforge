## 2024-07-08 - Dynamic tooltips for toggle buttons
**Learning:** Icon-only toggle buttons (like play/pause) need dynamic tooltips mapped to their state variables. Otherwise, the semantic label can fall out of sync with the visual icon or be missing entirely, leading to poor accessibility for screen readers.
**Action:** When adding or auditing toggle `IconButton` widgets in Flutter, ensure the `tooltip` property uses a ternary operator matching the visual icon state (e.g., `tooltip: playing ? 'Pause' : 'Play'`).
