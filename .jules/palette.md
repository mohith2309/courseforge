## 2024-06-25 - Missing tooltips on icon-only buttons
**Learning:** Icon-only buttons (like `IconButton` for play/pause) in Flutter need a `tooltip` property. This property not only shows a helpful visual tooltip on hover (for web/desktop), but also acts as the semantic label for screen readers on mobile devices, making the widget accessible.
**Action:** Always verify that `IconButton` and similar icon-only widgets have a `tooltip` property describing their action, especially if the action changes dynamically (e.g. Play vs Pause).
