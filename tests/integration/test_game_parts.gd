extends "res://tests/support/city_test.gd"
## M014: the composition - once the scene is up every shared part named in
## Game is built (none left null), main's own references are the same objects,
## every director works on that one Game, and a second scene builds its own
## (nothing shared between games, no Autoloads).


func _parts(g: Game) -> Array:
	var out := []
	for p in g.get_property_list():
		if int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out.append(String(p.name))
	return out


func test_every_part_is_built_once() -> void:
	var g: Game = main.game
	var names := _parts(g)
	assert_gt(names.size(), 50, "the parts Game names")
	for n in names:
		assert_not_null(g.get(n), "game.%s is built" % n)
	for n in ["rackets", "clock", "hud", "world", "walker", "player", "interiors", "soundscape", "weather", "layout"]:
		assert_same(main.get(n), g.get(n), "main.%s is game.%s" % [n, n])
	for n in ["dialogue", "people", "fights", "casualties", "districts", "incident_director", "films", "club", "armoury",
			"night", "interactions", "missions", "back_rooms", "fleet", "police", "modals", "saves"]:
		var director: Object = main.get(n)
		assert_same(director, g.get(n), n)
		assert_same(director.get("game"), g, "%s works on the one Game" % n)
	for j in main.missions.jobs:
		assert_same(j.get("game"), g)
	assert_same(g.root, main)


func test_a_second_game_shares_nothing() -> void:
	var other: Node2D = MAIN.instantiate()
	other.save_path = ""
	other.settings_path = ""
	other.opening_enabled = false
	other.callouts_enabled = false
	other.quiet_streets = true
	add_child_autofree(other)
	await wait_physics_frames(2)
	assert_ne(other.game, main.game)
	for n in ["rackets", "dialogue", "missions", "fleet", "saves"]:
		assert_ne(other.game.get(n), main.game.get(n), n)
	assert_same(other.game.root, other)
