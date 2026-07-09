## 2024-05-24 - Dynamic Tooltips for State-Driven IconButtons
**Learning:** In Flutter, dynamic toggle buttons (like play/pause `IconButton`) must have dynamic tooltips that map to the state variable driving the visual icon, ensuring screen readers can announce its accurate state and purpose synchronously.
**Action:** Always map the `tooltip` text to the exact boolean variable managing the visual toggle logic.
