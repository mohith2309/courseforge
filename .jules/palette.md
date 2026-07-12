## 2025-05-15 - Dynamic Tooltips for State-Toggled IconButtons
**Learning:** For `IconButton`s whose visual icon toggles based on state (e.g., Play/Pause), the `tooltip` property must also be dynamically mapped to that state to provide accurate semantic labels for screen readers and helpful context on hover.
**Action:** When adding `tooltip`s to interactive elements, ensure the text reflects the *current* state and the action that *will* happen upon interaction, dynamically switching if the visual representation switches.
