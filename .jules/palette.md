## 2023-10-25 - Dynamic Toggle Tooltips
**Learning:** For dynamic toggle buttons in Flutter (like Play/Pause), screen readers can read stale labels if the tooltip is not dynamically updated.
**Action:** The tooltip text must be mapped directly to the same state variable driving the visual icon (e.g., `tooltip: playing ? 'Pause' : 'Play'`) to ensure synchronous updates.
