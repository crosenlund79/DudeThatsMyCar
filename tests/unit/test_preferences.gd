extends GutTest
## M015: the player's preferences (not the save) - kept in the settings file's
## "game" section beside the sound levels, which they leave alone; with no
## path nothing is written.

const PATH := "user://test_preferences.cfg"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_kept_beside_the_sound_levels() -> void:
	var sound := AudioSettings.new(PATH)
	sound.set_volume("Music", 0.25)
	sound.save_settings()
	var p := Preferences.new(PATH)
	assert_eq(p.get_pref("roulette_pace"), "normal", "the default")
	p.set_pref("roulette_pace", "quick")
	var again := Preferences.new(PATH)
	again.load_prefs()
	assert_eq(again.get_pref("roulette_pace"), "quick")
	var sound2 := AudioSettings.new(PATH)
	sound2.load_settings()
	assert_almost_eq(float(sound2.volume["Music"]), 0.25, 0.001, "the sound levels untouched")
	sound2.save_settings()
	var third := Preferences.new(PATH)
	third.load_prefs()
	assert_eq(third.get_pref("roulette_pace"), "quick", "and the sound levels' save keeps them")


func test_no_path_no_file() -> void:
	var p := Preferences.new("")
	p.set_pref("roulette_pace", "relaxed")
	assert_eq(p.get_pref("roulette_pace"), "relaxed")
	assert_false(FileAccess.file_exists(PATH))
