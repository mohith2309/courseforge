## 2025-02-12 - Dynamic Tooltips for Icon Toggle Buttons
**Learning:** In Flutter, icon-only toggle buttons (like play/pause) need dynamic semantic labels to remain accessible as their state changes.
**Action:** Always map the `tooltip` property to the exact same state variable that drives the visual icon to ensure screen readers announce the correct action synchronously.
