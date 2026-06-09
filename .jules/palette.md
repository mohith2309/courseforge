## 2024-03-24 - Accessibility for icon-only widgets
**Learning:** In Flutter, using `IconButton` without a `tooltip` makes the interactive element inaccessible to screen readers because there's no visible text label to infer meaning from. The Play/Pause button and other control buttons often lack these descriptors.
**Action:** Always provide the `tooltip` property to `IconButton`s that rely solely on `Icon` widgets. It gives screen readers the required accessible label and adds a helpful hover popup for mouse users.
