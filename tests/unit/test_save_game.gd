extends GutTest
## M003 the save file: written and read back as it was; no path, no file.

const PATH := "user://test_save_game.json"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func test_round_trip() -> void:
	var r := Rackets.new(EconomyRules.new())
	r.buy_bottles(2)
	assert_true(SaveGame.write(PATH, {"rackets": r.to_dict()}))
	var back := SaveGame.read(PATH)
	assert_eq(int(back.version), SaveSchema.VERSION)  # M014: the format version lives with the schema
	var copy := Rackets.new(EconomyRules.new())
	copy.from_dict(back.rackets)
	assert_eq(copy.bottles, 2)
	assert_eq(copy.money, r.money)


func test_no_path_no_file() -> void:
	assert_false(SaveGame.write("", {"a": 1}))
	assert_eq(SaveGame.read(""), {})
	assert_eq(SaveGame.read("user://does_not_exist.json"), {})
