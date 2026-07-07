## 2024-07-07 - Semantic Labels for Dynamic Toggle Buttons
**Learning:** In Flutter, icon-only buttons (like `IconButton`) must include a `tooltip` property to provide semantic labels for screen readers. For dynamic toggle buttons (like play/pause), the tooltip text must be dynamically mapped to the state variable driving the visual icon to ensure synchronous updates (e.g., `tooltip: playing ? 'Pause' : 'Play'`).
**Action:** Always verify that state-driven icon buttons have correspondingly dynamic `tooltip` properties mapped to their state variables.
