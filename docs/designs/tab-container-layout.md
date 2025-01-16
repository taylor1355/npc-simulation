# Tab Container Layout Improvement

## Problem
The current TabContainer implementation only shows up to 2 tabs at once, requiring users to scroll horizontally to access other tabs. This creates friction in the UI as users need to constantly scroll to view different panels.

## Solution
Modify the TabContainer to show all tabs simultaneously by:
1. Setting the TabContainer's `tabs_visible` property to true (default)
2. Setting `clip_tabs` to false to prevent tab clipping/scrolling
3. Adjusting the container size to accommodate all tabs

## Implementation
In src/ui/tab_container.gd:
1. Add `clip_tabs = false` in _ready() to ensure all tabs are visible
2. The TabContainer will automatically adjust its layout to show all tabs

## Benefits
- Improved usability by showing all available tabs at once
- Reduced friction in UI navigation
- Better overview of available panels
- Consistent with standard UI patterns where tabs are fully visible

## Considerations
- Tab width will adjust based on number of tabs
- Text may be compressed if many tabs are present
- Overall container width remains the same
