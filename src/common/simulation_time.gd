extends Node

## Singleton that manages deterministic simulation time independent of real time.
## Provides time tracking and scaling for game systems.
## Registered as an autoload singleton in Project Settings.

# Time configuration
@export var time_scale: float = 60.0  ## 1 real second = 1 game minute by default
@export var paused: bool = false

# Time tracking - using unix timestamp for internal representation
var _unix_timestamp: float = 0.0

# Start date: March 1, Year 1, 06:00 (6 AM)
# We'll use a base offset to represent Year 1 as unix timestamp
const YEAR_1_OFFSET: int = -62135596800  # Approximate offset to Year 1
const START_MONTH: int = 3  # March
const START_DAY: int = 1
const START_HOUR: int = 6

# Subscription tracking
var _update_subscriptions: Dictionary = {}  # subscriber_id -> {interval: float, elapsed: float}

# Signal for subscription updates
signal time_update_for_subscriber(subscriber_id: String, time_dict: Dictionary)

func _ready() -> void:
	# Set process priority to run before other systems
	process_priority = Globals.ProcessPriorities.SIMULATION_TIME
	# Initialize to 6 AM on March 1, Year 1
	# Add days for January (30) and February (30) = 60 days
	var days_offset = (START_MONTH - 1) * 30 + (START_DAY - 1)
	_unix_timestamp = YEAR_1_OFFSET + (days_offset * 86400) + (START_HOUR * 3600)

func _process(delta: float) -> void:
	if paused:
		return
		
	# Update timestamp based on scaled time
	_unix_timestamp += delta * time_scale
	
	# Process update subscriptions
	for subscriber_id in _update_subscriptions:
		var subscription = _update_subscriptions[subscriber_id]
		subscription.elapsed += delta
		
		if subscription.elapsed >= subscription.interval:
			subscription.elapsed -= subscription.interval
			time_update_for_subscriber.emit(subscriber_id, get_current_time())

## Get the current simulation time as a datetime dictionary
func get_current_time() -> Dictionary:
	# Calculate time elapsed since Year 1 start
	var total_elapsed = _unix_timestamp - YEAR_1_OFFSET
	# Subtract the initial offset to get elapsed since March 1, 6 AM
	var initial_offset = ((START_MONTH - 1) * 30 * 86400) + (START_HOUR * 3600)
	var elapsed_seconds = total_elapsed - initial_offset
	
	# Calculate date components from elapsed time
	var total_days = int(elapsed_seconds / 86400)
	var remaining_seconds = int(elapsed_seconds) % 86400
	var hours = int(remaining_seconds / 3600) + START_HOUR
	var minutes = int((remaining_seconds % 3600) / 60)
	var seconds = int(remaining_seconds % 60)
	
	# Simple date calculation (30 days per month, 12 months per year)
	var years = int(total_days / 360)
	var remaining_days = total_days % 360
	var months = int(remaining_days / 30)
	var days = (remaining_days % 30)
	
	# Adjust for 1-based months and days, starting from March
	var final_year = 1 + years
	var final_month = START_MONTH + months
	var final_day = 1 + days
	
	# Handle month wraparound
	if final_month > 12:
		final_year += int((final_month - 1) / 12)
		final_month = ((final_month - 1) % 12) + 1
	
	# Handle hour overflow
	if hours >= 24:
		final_day += int(hours / 24)
		hours = hours % 24
	
	return {
		"year": final_year,
		"month": final_month,
		"day": final_day,
		"weekday": (total_days % 7) + 1,
		"hour": hours,
		"minute": minutes,
		"second": seconds
	}

## Format time with flexible options
## @param show_year: Include year in format
## @param show_date: Include month and day
## @param show_day_count: Show as "Day X" instead of date
## @param separator: String between date and time (default " - ")
## @param use_12_hour: Show time in 12-hour format with AM/PM
## @param show_time: Include time in the output (default true)
func format_time(show_year: bool = true, show_date: bool = true, 
				 show_day_count: bool = false, separator: String = " - ",
				 use_12_hour: bool = false, show_time: bool = true) -> String:
	var time = get_current_time()
	var parts = []
	
	if show_day_count:
		# Show as "Day X" format
		var days_elapsed = int((_unix_timestamp - YEAR_1_OFFSET) / 86400) + 1
		parts.append("Day %d" % days_elapsed)
	elif show_date:
		# Show as date format
		var month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", 
						   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
		var date_str = "%s %d" % [month_names[time.month - 1], time.day]
		if show_year:
			date_str += ", Year %d" % time.year
		parts.append(date_str)
	
	# Show time if requested
	if show_time:
		if use_12_hour:
			var hour_12 = time.hour % 12
			if hour_12 == 0:
				hour_12 = 12
			var am_pm = "AM" if time.hour < 12 else "PM"
			parts.append("%d:%02d %s" % [hour_12, time.minute, am_pm])
		else:
			parts.append("%02d:%02d" % [time.hour, time.minute])
	
	# Join with separator only if we have multiple parts
	if parts.size() > 1:
		return parts[0] + separator + parts[1]
	else:
		return parts[0]

## Set the simulation time using datetime components
func set_time(year: int, month: int, day: int, hour: int, minute: int, second: int = 0) -> void:
	# Create datetime dict
	var datetime = {
		"year": year + 1969,  # Convert Year 1 based to 1970 based
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second
	}
	
	# Convert to unix timestamp
	_unix_timestamp = Time.get_unix_time_from_datetime_dict(datetime)

## Pause or unpause the simulation
func set_paused(is_paused: bool) -> void:
	paused = is_paused

## Toggle pause state
func toggle_pause() -> void:
	paused = not paused

## Get total elapsed game seconds since start
func get_elapsed_seconds() -> int:
	var initial_offset = ((START_MONTH - 1) * 30 * 86400) + (START_HOUR * 3600)
	return int(_unix_timestamp - YEAR_1_OFFSET - initial_offset)

## Set the time scale (1.0 = real time, 60.0 = 1 minute per second)
func set_time_scale(scale: float) -> void:
	time_scale = max(0.0, scale)

## Advance time by a specific amount of game seconds
func advance_time(seconds: float) -> void:
	if seconds > 0:
		_unix_timestamp += seconds

## Subscribe to receive time updates at a specific interval
## @param subscriber_id: Unique identifier for the subscriber
## @param update_interval: How often to receive updates (in real seconds)
func subscribe_to_updates(subscriber_id: String, update_interval: float) -> void:
	if update_interval <= 0:
		push_error("Update interval must be positive")
		return
	
	_update_subscriptions[subscriber_id] = {
		"interval": update_interval,
		"elapsed": 0.0
	}

## Unsubscribe from time updates
func unsubscribe_from_updates(subscriber_id: String) -> void:
	_update_subscriptions.erase(subscriber_id)
