class_name NightClock
extends RefCounted
## The time of night (pure): it starts in the evening, runs while you play and
## stops at dawn; after the reminder hour it is time to get home. How lively
## the streets are follows the hour (activity), quieter towards morning.

var rules: NightRules
## Minutes after midnight of the evening the night began (past 1440 = next day).
var minute := 0.0


func _init(p_rules: NightRules = null) -> void:
	rules = p_rules if p_rules != null else NightRules.new()
	reset()


## Back to the start of an evening.
func reset() -> void:
	minute = float(rules.start_minute)


func advance(seconds: float) -> void:
	minute = minf(minute + seconds * rules.minutes_per_second, float(rules.dawn_minute))


func set_time(p_minute: float) -> void:
	minute = clampf(p_minute, float(rules.start_minute), float(rules.dawn_minute))


## Time to head home (the reminder hour has passed).
func is_late() -> bool:
	return minute >= rules.home_minute


## M010: how drowsy Danny is (0 until the drowsy hour, growing to 1 at dawn).
func drowsiness() -> float:
	var span := float(rules.dawn_minute - rules.drowsy_minute)
	if span <= 0.0 or minute <= rules.drowsy_minute:
		return 0.0
	var t := clampf((minute - rules.drowsy_minute) / span, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## The clock has stopped at dawn.
func is_dawn() -> bool:
	return minute >= rules.dawn_minute


## "7:30 PM", "12:05 AM", "4:00 AM".
func text() -> String:
	var m := int(minute) % (24 * 60)
	var h := m / 60
	var suffix := "AM" if h < 12 else "PM"
	var h12 := h % 12
	if h12 == 0:
		h12 = 12
	return "%d:%02d %s" % [h12, m % 60, suffix]


## How busy the streets are, 1 in the evening down to about 0.2 before dawn:
## full until 11 pm, then falling off through the small hours.
func activity() -> float:
	var after_eleven := (minute - 23.0 * 60.0) / 60.0  # hours past 11 pm
	if after_eleven <= 0.0:
		return 1.0
	return clampf(1.0 - after_eleven * 0.16, 0.2, 1.0)
