extends "res://tests/support/city_test.gd"
## M014: a scene that is freed lets go of its whole game - the Game object,
## every director, the books, the layouts - so reloading (the menu's "Load the
## last save") never keeps the old game in memory. RefCounted objects that
## refer to each other are not collected by themselves; main releases the Game
## as it is freed (Game.release).


func test_a_freed_scene_frees_its_game() -> void:
	var refs := {}
	var g: Game = main.game
	refs["game"] = weakref(g)
	for n in ["dialogue", "people", "fights", "casualties", "districts", "incident_director", "films", "club", "armoury",
			"night", "interactions", "missions", "fleet", "police", "modals", "saves", "rourke_job", "errands", "freight",
			"cafe", "last_song", "rackets", "layout", "locations", "talk", "clock", "voice_lines", "incidents", "weather"]:
		refs[n] = weakref(g.get(n))
	g = null
	await talk_to("copper_owl", "augie")  # a talk under way, its hooks registered
	remove_child(main)
	main.free()
	main = null
	await wait_physics_frames(3)
	for n in refs:
		assert_null(refs[n].get_ref(), "%s freed with its scene" % n)
	# a new scene for after_each and the next test
	main = MAIN.instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.callouts_enabled = false
	add_child_autofree(main)
	await wait_physics_frames(2)
