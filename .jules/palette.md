## 2024-06-25 - [Accessibility: Dynamic Icon Tooltips]
**Learning:** In Flutter, icon-only buttons (like IconButton) require a `tooltip` property to provide semantic labels for screen readers. For dynamic toggle buttons (e.g. play/pause), the tooltip text must be mapped directly to the same state variable driving the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure synchronous updates.
**Action:** Always verify that IconButtons have a `tooltip` property, especially when the icon changes dynamically.
