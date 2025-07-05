# Known Bugs

## Visual/Animation Issues

### NPC Nameplate Z-Index Issue
- **Description**: NPC nameplates have incorrect z-index ordering, appearing above the ground tilemap layer but below the layer above it
- **Steps to Reproduce**: Observe NPC nameplates in relation to different tilemap layers
- **Expected**: Nameplates should render at the correct depth relative to world elements
- **Actual**: Nameplates appear between tilemap layers incorrectly

## Conversation System Issues

### Integration Problems with Conversation Flow
- **Description**: Major issues with conversation system integration causing incorrect state transitions and message blocking
- **Symptoms**: 
  - NPCs attempting to wander during active conversations
  - Message delays not working correctly (messages blocked with "3.0s delay needed")
  - State transitions happening mid-conversation (moving_to_item_state -> wandering_state during interaction)
  - Participants not properly maintaining the INTERACTING state
- **Example Log**: Shows NPC 81000400886 transitioning states and attempting to wander while in a conversation
- **Impact**: Conversations break down as participants leave or perform other actions mid-conversation

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

### Panels Resize Incorrectly on Screen Size Change
- **Description**: UI panels and tabs resize when the screen size changes, but the resizing/repositioning is incorrect
- **Steps to Reproduce**: Run the game and resize the window or change screen resolution
- **Expected**: Panels should correctly resize and reposition to maintain proper layout and proportions
- **Actual**: Panels resize but with incorrect dimensions or positioning, causing layout issues
- **Impact**: UI elements may overlap, have incorrect spacing, or not utilize screen space properly