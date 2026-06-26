
## 2024-06-26 - Dynamic Tooltips for Accessibility
**Learning:** For dynamic toggle buttons like play/pause, mapping the tooltip text directly to the same state variable driving the visual icon ensures synchronous updates and proper semantic labels for accessibility.
**Action:** Always include a `tooltip` property on icon-only buttons (`IconButton`), dynamically updating the text if the icon state changes.
