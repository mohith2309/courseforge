## 2024-10-24 - Dynamic Tooltips on Toggle Buttons
**Learning:** For interactive icon-only buttons that toggle state (like play/pause), a static tooltip is insufficient. Screen readers and users rely on the tooltip matching the *current* action the button will perform.
**Action:** When adding tooltips to stateful icon-only buttons, map the tooltip string to the state variable that drives the icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure they stay perfectly in sync.
