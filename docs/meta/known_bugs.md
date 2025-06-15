# Known Bugs

## Visual/Animation Issues

### NPCs Don't Face Items When Consuming
- **Description**: NPCs don't turn to face items when consuming them, making the interaction look unnatural
- **Steps to Reproduce**: Have an NPC consume any item
- **Expected**: NPC should face the item before/during consumption
- **Actual**: NPC consumes item while facing their current direction

### NPC Z-Order Issue After Sitting
- **Description**: When NPCs get up from chairs, they sometimes appear behind the chair instead of in front
- **Steps to Reproduce**: Have an NPC sit on a chair, then get up
- **Expected**: NPC should maintain proper layering relative to furniture
- **Actual**: NPC appears behind the chair after standing
- **Likely Cause**: Y-sorting or z-index not properly restored after sitting interaction

## UI Issues

### Debug Console Loses Focus
- **Description**: The debug console loses focus after pressing Enter to submit a command
- **Steps to Reproduce**: Open debug console with backtick, type a command, press Enter
- **Expected**: Console should maintain focus for typing additional commands
- **Actual**: Focus is lost and requires clicking to regain