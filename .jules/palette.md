## 2024-06-25 - Dynamic Toggle Button Accessibility in Flutter
**Learning:** For dynamic toggle buttons (like play/pause or mute/unmute) in Flutter using `IconButton`, the tooltip text must be mapped directly to the same state variable driving the visual icon to ensure synchronous updates and correct screen reader announcements.
**Action:** Always include a `tooltip` property with dynamic text (e.g., `tooltip: isActive ? 'Stop' : 'Start'`) on icon-only toggle buttons to ensure accessibility labels stay in sync with the visual state.
