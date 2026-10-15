## 2026-06-21 - Dynamic Tooltips on Stateful Icon Buttons
**Learning:** In Flutter, icon-only buttons (like `IconButton`) must include a `tooltip` property to provide semantic labels for accessibility. For dynamic toggle buttons, the tooltip text must be mapped directly to the same state variable driving the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure synchronous updates.
**Action:** Always add dynamic tooltips matched to the driving state variable when implementing toggleable `IconButton`s.
