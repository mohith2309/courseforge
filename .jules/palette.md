## 2026-06-08 - [Added Tooltip to IconButtons]
**Learning:** Dynamic IconButtons, like the play/pause button in lesson player, often get missed for accessibility labels because their icons change based on state. Without `tooltip`, screen readers announce nothing.
**Action:** Always add stateful tooltips to dynamically updating IconButtons.
