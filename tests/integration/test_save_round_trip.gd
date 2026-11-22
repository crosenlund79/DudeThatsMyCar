extends "res://tests/support/city_test.gd"
## M014: saving and loading in the game. Every real save from M003 to M013
## loads, is written back at the current format with every section its owner
## keeps, and that file loads to the same game again (the books, who Danny
## has met, his wounds, who is out, the guns, the cars, where and when). A
## save the game cannot read starts a new game and is kept aside, never lost.

const SAVE := "user://test_save_round_trip.json"
const FIXTURES := ["m003", "m005", "m006", "m007", "m008", "m009", "m010", "m011", "m012", "m013"]


func after_each() -> void:
	super()
	for p in [SAVE, SaveGame.unreadable_path(SAVE)]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))


## A new scene on `text` as its save file - nothing run yet (the night does not
## move on between loading and writing it again).
func _start(text: String) -> void:
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE
	main.settings_path = ""
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()


func _written() -> Dictionary:
	main.save_game()
	return JSON.parse_string(FileAccess.get_file_as_string(SAVE))


## What a save keeps that must come back the same (the place's minute and the
## cars may move on a little between the save and the snapshot).
func _kept(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	out.erase("version")
	if out.has("place"):
		out.place.erase("minute")
	return out


func test_every_milestones_save_round_trips() -> void:
	for fixture in FIXTURES:
		var text := FileAccess.get_file_as_string("res://tests/fixtures/saves/%s.json" % fixture)
		var original: Dictionary = JSON.parse_string(text)
		await _start(text)
		assert_eq(main.saves.read_version, 1, fixture)
		assert_eq(main.saves.problems, [], fixture)
		assert_null(main.films.of("opening"), "%s: a loaded game never plays the opening" % fixture)
		assert_eq(main.rackets.money, int(original.rackets.money), "%s: the money" % fixture)
		assert_eq(main.rackets.night, int(original.rackets.night), fixture)
		var first := _written()
		assert_eq(int(first.version), SaveSchema.VERSION, "%s: written at the current format" % fixture)
		for key in SaveSchema.SECTIONS:
			if key != "place" or original.has("place"):
				assert_true(first.has(key), "%s: '%s' written by its owner" % [fixture, key])
		await _start(JSON.stringify(first))
		assert_eq(main.saves.read_version, SaveSchema.VERSION, fixture)
		var second := _written()
		var diffs := _diff(_kept(first), _kept(second), "")
		assert_eq(diffs, [], "%s: loads back to the same game" % fixture)


func test_an_unreadable_save_starts_afresh_and_is_kept() -> void:
	await _start("{ this is not a save")
	await wait_physics_frames(3)
	assert_eq(main.rackets.night, 1, "a new game")
	assert_eq(main.rackets.money, main.economy_rules.start_money, "with the starting money")
	assert_true(FileAccess.file_exists(SaveGame.unreadable_path(SAVE)), "the old file kept aside")
	assert_eq(FileAccess.get_file_as_string(SaveGame.unreadable_path(SAVE)), "{ this is not a save")


func test_a_malformed_section_does_not_stop_the_game() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/saves/m013.json"))
	data["slots"] = "jammed"
	data["cars"] = {"moved": {}}  # no night
	await _start(JSON.stringify(data))
	await wait_physics_frames(3)
	assert_eq(main.saves.problems.size(), 2)
	assert_eq(main.rackets.money, int(data.rackets.money), "the rest of the save is there")
	assert_true(main.player.on_foot(), "the cars as at the start of a night")
	assert_eq(main.back_rooms.slot_machines.size(), 3, "the machines fresh")


func _diff(a: Variant, b: Variant, path: String) -> Array:
	if a is Dictionary and b is Dictionary:
		var out := []
		for k in a:
			out.append_array(_diff(a[k], b.get(k), path + "/" + str(k)) if b.has(k) else [path + "/" + str(k) + " missing"])
		for k in b:
			if not a.has(k):
				out.append(path + "/" + str(k) + " new")
		return out
	if a is Array and b is Array and a.size() == b.size():
		var out := []
		for i in a.size():
			out.append_array(_diff(a[i], b[i], path + "[%d]" % i))
		return out
	if (a is float or a is int) and (b is float or b is int):  # (a float32 in the model, a double in the file)
		return [] if absf(float(a) - float(b)) <= 0.001 * maxf(1.0, absf(float(a))) else ["%s: %s -> %s" % [path, a, b]]
	return [] if str(a) == str(b) else ["%s: %s -> %s" % [path, str(a).left(60), str(b).left(60)]]
