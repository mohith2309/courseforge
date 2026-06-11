## 2024-05-18 - Dynamic Tooltips for Icon-only Buttons
**Learning:** In Flutter, it is important to add a `tooltip` parameter to `IconButton`s that lack text labels, ensuring accessibility. When the icon dynamically changes based on state (e.g., play/pause), the tooltip should also dynamically change to reflect the current action using a ternary operator (e.g., `tooltip: playing ? "Pause" : "Play"`).
**Action:** Always provide dynamic tooltips for state-dependent icon-only buttons to keep accessibility labels synchronously updated with the UI state.
