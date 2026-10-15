## 2024-05-24 - Dynamic Tooltips for Icon Toggle Buttons
**Learning:** For dynamic toggle buttons like Play/Pause, the tooltip text must be mapped directly to the same state variable driving the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure synchronous updates and proper accessibility context.
**Action:** Always provide state-dependent semantic labels for icon-only toggle buttons in Flutter to maintain accurate accessibility descriptors.
