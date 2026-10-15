## 2024-05-18 - Missing Tooltip on Dynamic Play/Pause Button
**Learning:** Icon-only buttons (like `IconButton`) in Flutter must include a `tooltip` property to provide semantic labels for accessibility, especially when their icon dynamically changes state. Without it, screen readers only announce a generic button type without conveying its current action or state.
**Action:** Always map the `tooltip` text directly to the same state variable driving the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure synchronous semantic and visual updates.
