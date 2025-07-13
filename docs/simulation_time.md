# Simulation Time System

## Overview

The `SimulationTime` singleton manages deterministic game time independent of real-world time. It provides consistent time tracking across all game systems with configurable time scaling and pause functionality.

## Features

- **Deterministic Time**: All systems use the same simulated time source
- **Time Scaling**: Configurable speed (default: 1 real second = 1 game minute)
- **Pause Support**: Freeze simulation time while keeping UI responsive
- **Subscription System**: Systems can subscribe to time updates at custom intervals
- **Flexible Formatting**: Multiple display options for dates and times

## Time Configuration

The simulation starts at **6:00 AM on March 1, Year 1** and advances based on the time scale:

```gdscript
# Default configuration
time_scale = 60.0  # 1 real second = 1 game minute
paused = false     # Start unpaused
```

The calendar uses a simplified system:
- 30 days per month
- 12 months per year
- 360 days per year

## Usage

### Basic Time Access

```gdscript
# Get current time as a dictionary
var time = SimulationTime.get_current_time()
# Returns: {year: 1, month: 3, day: 1, weekday: 1, hour: 6, minute: 0, second: 0}

# Get elapsed seconds since start
var elapsed = SimulationTime.get_elapsed_seconds()

# Format time for display (many options available)
var display = SimulationTime.format_time()  # "Mar 1, Year 1 - 6:00 AM"
```

### Time Control

```gdscript
# Pause/unpause simulation
SimulationTime.set_paused(true)
SimulationTime.toggle_pause()

# Change time scale (60.0 = 1 minute/second, 3600.0 = 1 hour/second)
SimulationTime.set_time_scale(120.0)  # 2 minutes per second

# Advance time manually
SimulationTime.advance_time(3600.0)  # Add 1 hour

# Set specific time
SimulationTime.set_time(1, 6, 15, 14, 30)  # Year 1, June 15, 2:30 PM
```

### Subscription System

Systems can subscribe to receive time updates at regular intervals:

```gdscript
# In _ready()
const UPDATE_ID = "my_system_time"
SimulationTime.subscribe_to_updates(UPDATE_ID, 0.5)  # Update every 0.5 seconds
SimulationTime.time_update_for_subscriber.connect(_on_time_update)

# Handle updates
func _on_time_update(subscriber_id: String, time_dict: Dictionary) -> void:
    if subscriber_id == UPDATE_ID:
        # Update display or logic based on new time
        print("Current time: ", SimulationTime.format_time())

# In _exit_tree()
SimulationTime.unsubscribe_from_updates(UPDATE_ID)
```

### Formatting Options

The `format_time()` method provides extensive formatting control:

```gdscript
# Full date and time
SimulationTime.format_time()  # "Mar 1, Year 1 - 6:00 AM"

# Just time
SimulationTime.format_time(false, false, false, "", true, true)  # "6:00 AM"

# Just date
SimulationTime.format_time(true, true, false, "", false, false)  # "Mar 1, Year 1"

# Day count format
SimulationTime.format_time(false, false, true)  # "Day 1 - 6:00 AM"

# 24-hour format
SimulationTime.format_time(true, true, false, " - ", false)  # "Mar 1, Year 1 - 06:00"

# Custom separator
SimulationTime.format_time(true, true, false, " at ")  # "Mar 1, Year 1 at 6:00 AM"
```

## Integration Examples

### UI Status Bar

The bottom UI status bar uses SimulationTime for its display:

```gdscript
# Subscribe for frequent updates
SimulationTime.subscribe_to_updates(TIME_UPDATE_ID, 0.1)  # 10 fps

# Format for status display
var time_str = SimulationTime.format_time(false, false, false, "", true, true)
var date_str = SimulationTime.format_time(true, true, false, "", false, false)
status_label.text = "%s  •  %s  •  Pos: %d, %d" % [date_str, time_str, x, y]
```

### NPC Scheduling

NPCs could use time for behavior scheduling:

```gdscript
# Check if it's nighttime (after 8 PM or before 6 AM)
var time = SimulationTime.get_current_time()
if time.hour >= 20 or time.hour < 6:
    # Nighttime behavior
    needs_manager.modify_need("energy", -2.0)  # Extra tired at night
```

### Event Timing

Track how long events or interactions have lasted:

```gdscript
# Store start time
var start_seconds = SimulationTime.get_elapsed_seconds()

# Later, calculate duration
var duration = SimulationTime.get_elapsed_seconds() - start_seconds
print("Interaction lasted %d game minutes" % (duration / 60))
```

## Process Priority

SimulationTime runs at priority `-1001` (defined in `Globals.ProcessPriorities.SIMULATION_TIME`), ensuring it updates before other game systems that depend on time.

## Best Practices

1. **Always Unsubscribe**: Clean up subscriptions in `_exit_tree()` to prevent memory leaks
2. **Use Appropriate Intervals**: Don't subscribe more frequently than needed (UI: 0.1s, Logic: 1.0s)
3. **Cache Formatted Strings**: If displaying time every frame, subscribe rather than formatting each frame
4. **Respect Pause State**: Check `SimulationTime.paused` before time-based logic
5. **Use Consistent IDs**: Define subscription IDs as constants for maintainability

## Time Scale Examples

Common time scale values:

- `1.0` = Real-time (1 second = 1 second)
- `60.0` = Default (1 second = 1 minute)
- `3600.0` = Fast (1 second = 1 hour)
- `86400.0` = Very Fast (1 second = 1 day)
- `0.0` = Effectively paused

## Future Extensions

The system is designed to support:

- Seasonal changes based on month
- Day/night cycles based on hour
- Scheduled events and behaviors
- Save/load of time state
- Time-based NPC routines