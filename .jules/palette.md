## 2026-06-27 - Dynamic Tooltips for Icon Toggle Buttons
**Learning:** In Flutter, icon-only toggle buttons (e.g., play/pause) can be confusing for screen readers and sighted users alike if their semantic label doesn't update synchronously with the icon state. The `tooltip` property on `IconButton` is essential for accessibility.
**Action:** Always map the `tooltip` text directly to the same boolean state variable that drives the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure consistent, accessible interaction states across the app.
