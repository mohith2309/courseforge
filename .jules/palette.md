## 2024-05-19 - Dynamic Tooltips for Icon Buttons
**Learning:** For `IconButton` widgets in Flutter that toggle their state (like Play/Pause), it's critical to tie the `tooltip` directly to the same state variable that drives the icon itself (e.g., `tooltip: playing ? 'Pause' : 'Play'`). Without a tooltip, these buttons lack semantic labels for screen readers.
**Action:** Always verify that dynamic icon-only toggles have dynamically updating `tooltip` or `semanticLabel` properties to ensure accessibility remains synchronized with the visual state.
