class_name Weather
extends RefCounted
## M010: the night's weather - clear, rain, street fog, or rain and fog together
## - as two plain levels (0..1) on the night clock. Each night has its own
## course (the first nights written by hand, the rest from the night's seed),
## changes come on gradually over a quarter of an hour or so, and the rain
## varies a little in strength as it falls. No simulation: the same night
## always has the same weather, so tests and screenshots can rely on it (and
## force a state at once). Saved with nothing: a game always starts at dusk,
## and the night fixes the course.

const STATES := ["clear", "rain", "fog", "rain_fog"]
const LEVELS := {"clear": [0.0, 0.0], "rain": [1.0, 0.0], "fog": [0.0, 1.0], "rain_fog": [0.85, 0.8]}
## Game minutes for a change to come on in full.
const CHANGE_MINUTES := 18.0
## The courses: [[minutes after dusk, state], ...]. Night 1: a wet evening, the
## fog creeping in after ten, the rain easing off after one, fog till dawn.
const COURSES := {
	1: [[0, "rain"], [150, "rain_fog"], [330, "fog"]],
	2: [[0, "clear"], [200, "fog"], [420, "clear"]],
	3: [[0, "clear"], [260, "rain"], [380, "clear"]],
}
const PATTERNS := [
	[[0, "clear"]],
	[[0, "rain"], [240, "clear"]],
	[[0, "clear"], [180, "fog"]],
	[[0, "fog"], [120, "rain_fog"], [300, "rain"], [420, "clear"]],
	[[0, "clear"], [220, "rain"]],
]

var night := 0
var rain := 0.0
var fog := 0.0
var minute := 0.0
## A state forced at once (tests, screenshots); "" follows the night's course.
var forced := ""
var _course: Array = []
var _dusk := 0.0


static func course_of(n: int) -> Array:
	if COURSES.has(n):
		return COURSES[n]
	var rng := RandomNumberGenerator.new()
	rng.seed = 1932010 + n * 104729
	return PATTERNS[rng.randi_range(0, PATTERNS.size() - 1)]


## A new night: its course, and the weather it starts with (no change at dusk).
func begin_night(n: int, dusk_minute: float) -> void:
	night = n
	_dusk = dusk_minute
	minute = dusk_minute
	_course = course_of(n)
	var lv: Array = LEVELS[target_state()]
	rain = lv[0]
	fog = lv[1]


## The state the course asks for now (or the forced one).
func target_state() -> String:
	if forced != "":
		return forced
	var s := "clear"
	for step in _course:
		if minute - _dusk >= float(step[0]):
			s = step[1]
	return s


## Force a state at once ("" goes back to the night's course, gradually).
func force(state: String) -> void:
	forced = state
	if state != "":
		var lv: Array = LEVELS[state]
		rain = lv[0]
		fog = lv[1]


## The clock reached `p_minute`: the levels move towards what the course asks.
func advance(p_minute: float) -> void:
	var dt := maxf(0.0, p_minute - minute)
	minute = p_minute
	var lv: Array = LEVELS[target_state()]
	rain = move_toward(rain, lv[0], dt / CHANGE_MINUTES)
	fog = move_toward(fog, lv[1], dt / CHANGE_MINUTES)


## How hard it is raining now (the rain level, varying gently as it falls).
func rain_strength() -> float:
	var t := minute * 0.35 + night * 13.0
	var wobble := 0.78 + 0.14 * sin(t) + 0.08 * sin(t * 2.7 + 1.3)
	return clampf(rain * wobble, 0.0, 1.0)


## The state as people would name it.
func state_name() -> String:
	if rain > 0.5 and fog > 0.5:
		return "rain_fog"
	if rain > 0.5:
		return "rain"
	if fog > 0.5:
		return "fog"
	return "clear"
