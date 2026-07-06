## 2024-07-06 - Missing Tooltips on Dynamic IconButtons
**Learning:** IconButtons with dynamic state icons (like play/pause) often lack semantic tooltips in Flutter, which degrades accessibility for screen reader users as they only hear 'button' without understanding its current action state.
**Action:** Always ensure that an `IconButton` that switches icons based on state also has a dynamically updating `tooltip` property (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to provide synchronous, meaningful labels.
