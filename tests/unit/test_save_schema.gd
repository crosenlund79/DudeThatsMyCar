extends GutTest
## M014: the save format - its version, its sections, the migration from
## version 1 (every M003-M013 save, real files written by each milestone's own
## code in tests/fixtures/saves/) and the checks a file must pass.

const FIXTURES := ["m003", "m005", "m006", "m007", "m008", "m009", "m010", "m011", "m012", "m013"]


func _fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/saves/%s.json" % name))


func test_versions() -> void:
	assert_eq(SaveSchema.version_of({}), 0, "no save")
	assert_eq(SaveSchema.version_of({"rackets": {}}), 1, "no version written: an old save")
	assert_eq(SaveSchema.version_of({"version": 1.0}), 1)
	assert_eq(SaveSchema.version_of({"version": 2}), 2)
	assert_eq(SaveSchema.version_of({"version": "two"}), 1, "a version that is not a number reads as the oldest")


func test_every_milestone_wrote_version_one() -> void:
	for f in FIXTURES:
		assert_eq(SaveSchema.version_of(_fixture(f)), 1, f)


func test_migrating_to_two() -> void:
	for f in FIXTURES:
		var old := _fixture(f)
		var m := SaveSchema.migrate(old)
		assert_eq(int(m.version), SaveSchema.VERSION, f)
		assert_true(m.has("voices"), "%s: who Danny has met is written down" % f)
		for key in old:
			if key != "version" and key != "voices":
				assert_eq(m[key], old[key], "%s: '%s' unchanged" % [f, key])
		assert_eq(SaveSchema.migrate(m), m, "%s: migrating again changes nothing" % f)
		assert_eq(int(old.version), 1, "the original left alone")


func test_saves_from_before_the_voices_know_their_old_acquaintances() -> void:
	for f in ["m003", "m005"]:
		var m := SaveSchema.migrate(_fixture(f))
		var heard: Array = m.voices.heard
		heard.sort()
		var want := SaveSchema.OLD_ACQUAINTANCES.duplicate()
		want.sort()
		assert_eq(heard, want, f)
		var v := VoiceLines.new()
		v.from_dict(m.voices)
		var old := VoiceLines.new()
		old.assume_old_acquaintances()
		assert_eq(v.to_dict(), old.to_dict(), "%s: the same as the old rule at load time" % f)
	for f in ["m006", "m013"]:
		assert_eq(SaveSchema.migrate(_fixture(f)).voices, _fixture(f).voices, "%s: its own record kept" % f)


func test_a_new_game_and_a_later_version() -> void:
	assert_eq(SaveSchema.migrate({}), {}, "no save stays no save")
	var later := {"version": SaveSchema.VERSION + 1, "rackets": {"money": 5}, "unknown": [1]}
	assert_eq(SaveSchema.migrate(later), later, "a later format is used as it is, as far as it goes")


func test_every_real_save_passes_the_checks() -> void:
	for f in FIXTURES:
		var checked := SaveSchema.validate(SaveSchema.migrate(_fixture(f)))
		assert_eq(checked.problems, [], f)
		assert_eq((checked.data as Dictionary).size(), _fixture(f).size() + (0 if _fixture(f).has("voices") else 1), f)


func test_malformed_sections_are_dropped_not_fatal() -> void:
	var bad := {"version": 2, "rackets": {"money": "a lot"}, "voices": [1, 2], "slots": {}, "place": {"x": 1},
		"cars": {"night": "one"}, "gun": {"ammo": 3}}
	var checked := SaveSchema.validate(bad)
	var data: Dictionary = checked.data
	assert_false(data.has("rackets"), "money that is not a number")
	assert_false(data.has("voices"), "a list where a section belongs")
	assert_false(data.has("slots"), "a section where a list belongs")
	assert_false(data.has("place"), "a place without its night")
	assert_false(data.has("cars"), "cars without their night")
	assert_true(data.has("gun"), "a good section kept")
	assert_eq((checked.problems as Array).size(), 5)
	assert_eq(SaveSchema.validate([1, 2]).data, {}, "not a save at all: a new game")
	assert_eq(SaveSchema.validate("text").data, {})


func test_every_section_has_an_owner_and_a_place_in_the_restoring() -> void:
	for key in SaveSchema.SECTIONS:
		assert_true(SaveSchema.RESTORE_ORDER.has(key), key)
		assert_ne(String(SaveSchema.SECTIONS[key].owner), "", key)
	assert_eq(SaveSchema.RESTORE_ORDER.size(), SaveSchema.SECTIONS.size())
	assert_eq(SaveSchema.RESTORE_ORDER[0], "rackets", "the books first")
	for f in FIXTURES:
		for key in _fixture(f):
			assert_true(key == "version" or SaveSchema.SECTIONS.has(key), "%s: '%s' is a known section" % [f, key])


func test_an_unreadable_file_is_kept_aside() -> void:
	var path := "user://test_save_schema_broken.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{\"rackets\": {\"money\": 12")
	f.close()
	assert_eq(SaveGame.read(path), {}, "it cannot be read: a new game")
	var kept := SaveGame.unreadable_path(path)
	assert_true(FileAccess.file_exists(kept), "a copy beside it")
	assert_eq(FileAccess.get_file_as_string(kept), "{\"rackets\": {\"money\": 12")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(kept))
