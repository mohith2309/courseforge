## 2024-05-18 - Dynamic Tooltips for Playback Controls
**Learning:** Flutter`s `IconButton` components that handle dynamic state (like play/pause) can seamlessly use a ternary operator for the `tooltip` property to ensure the accessibility label updates synchronously with the visual icon change.
**Action:** Always map the `tooltip` text directly to the state variable driving the visual icon to keep screen readers and hover hints perfectly synced with UI state.
