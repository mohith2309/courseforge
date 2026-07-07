## 2026-07-01 - Synchronous Tooltips for Dynamic IconButtons
**Learning:** When using dynamic state for icons (e.g., play/pause), the tooltip must also use the same state variable (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure accessibility labels accurately reflect the current visual state and intended action.
**Action:** Always map dynamic tooltips directly to the same state variable that drives the icon visual changes.
