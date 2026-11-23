class_name Preferences
extends RefCounted
## M015: the player's own preferences for how the game is played (not the
## save: they hold across games) - the wheel's betting timer so far. Kept in
## the settings file beside the sound levels (section "game"); with no path
## (tests, screenshots) they live in memory only and nothing is written.

const SECTION := "game"
const DEFAULTS := {"roulette_pace": RouletteRules.DEFAULT_PACE}

var path := ""
var values := {}


func _init(p_path := "") -> void:
	path = p_path
	values = DEFAULTS.duplicate()


func load_prefs() -> void:
	if path == "":
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for key in DEFAULTS:
		var v: Variant = cfg.get_value(SECTION, key, values[key])
		if typeof(v) == typeof(DEFAULTS[key]):
			values[key] = v


func get_pref(key: String) -> Variant:
	return values.get(key, DEFAULTS.get(key))


## Sets a preference and keeps it (the file's other sections are left as they are).
func set_pref(key: String, value: Variant) -> void:
	values[key] = value
	if path == "":
		return
	var cfg := ConfigFile.new()
	cfg.load(path)
	cfg.set_value(SECTION, key, value)
	cfg.save(path)
