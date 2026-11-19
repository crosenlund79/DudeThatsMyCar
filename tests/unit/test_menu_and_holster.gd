extends GutTest
## M012 the game menu's pure parts and the holster: the Notebook lists what is
## under way in Danny's own terms (nothing when nothing is); a gun drawn with H
## stays out until put away, keeps its rounds and is put away by H; the menu
## goes round its entries, opens pages, goes back with Esc and asks the game to
## resume, save, load or quit; Cheats is a page of none.


## A night with nothing of its own under way (no crate, no reel tonight).
func _rackets() -> Rackets:
	var r := Rackets.new(EconomyRules.new())
	r.opportunities.crate = "none"
	r.opportunities.reel = "none"
	return r


func test_the_notebook_is_empty_when_nothing_is_under_way() -> void:
	assert_eq(Notebook.entries(_rackets(), 20 * 60.0), [])


func test_the_notebook_follows_rourkes_jobs() -> void:
	var r := _rackets()
	r.job.stage = RourkeJob.Stage.OFFERED
	var e := Notebook.entries(r, 21 * 60.0)
	assert_eq(e.size(), 1)
	assert_string_contains(e[0].lines[0], "Lindqvist Hardware")
	r.job.stage = RourkeJob.Stage.ACCEPTED
	assert_string_contains(Notebook.entries(r, 21 * 60.0)[0].lines[0], "Find out who", "before he knows")
	r.job.learn("culprit")
	assert_string_contains(Notebook.entries(r, 21 * 60.0)[0].lines[0], "Lefty Moran", "once he knows")
	r.job.stage = RourkeJob.Stage.REPORTED
	assert_eq(Notebook.entries(r, 21 * 60.0), [], "done and told: off the page")
	r.cafe.stage = CafeJob.Stage.ACCEPTED
	var line: String = Notebook.entries(r, 22 * 60.0)[0].lines[0]
	assert_string_contains(line, "Rosie's Café")
	assert_string_contains(line, "first", "no parcel yet")
	r.parcels = 1
	assert_string_contains(Notebook.entries(r, 22 * 60.0)[0].lines[0], "in your coat")


func test_the_notebook_keeps_the_errands_and_the_thompson() -> void:
	var r := _rackets()
	r.opportunities.crate = "waiting"
	assert_eq(Notebook.entries(r, 22 * 60.0).size(), 1, "Dutch has a crate")
	assert_eq(Notebook.entries(r, Opportunities.CRATE_UNTIL + 1.0).size(), 0, "not once he has stopped asking")
	r.opportunities.crate = "loaded"
	assert_string_contains(Notebook.entries(r, 25 * 60.0)[0].lines[0], "boot")
	r.opportunities.crate = "delivered"
	r.opportunities.reel = "found"
	assert_string_contains(Notebook.entries(r, 22 * 60.0)[0].lines[0], "film can")
	r.opportunities.reel = "returned"
	r.loan.out = true
	assert_string_contains(Notebook.entries(r, 22 * 60.0)[0].title, "Thompson")


func test_a_gun_drawn_with_h_stays_out_until_put_away() -> void:
	var g := Gun.new(GunRules.new())
	g.ammo = 5
	assert_true(g.toggle_kept(), "H: drawn")
	for i in 60 * 30:  # half a minute without a shot
		g.step(1.0 / 60.0)
	assert_true(g.is_drawn(), "still in hand: kept out on purpose")
	assert_eq(g.ammo, 5, "no round spent")
	assert_false(g.toggle_kept(), "H again: put away")
	assert_false(g.is_drawn())
	assert_eq(g.ammo, 5, "rounds kept")
	# drawn by a click instead, it goes back under the coat by itself as before
	g.trigger()
	var holstered := false
	for i in 60 * 30:
		if "holstered" in g.step(1.0 / 60.0):
			holstered = true
	assert_true(holstered, "the old way: back under the coat after a while")
	g.toggle_kept()
	g.holster()
	assert_false(g.kept, "getting into a car (holster) forgets it")


func test_the_menu_goes_round_its_entries_and_asks_for_actions() -> void:
	var m := GameMenu.new()
	add_child_autofree(m)
	m.setup(AssetResolver.new(""), load("res://assets/fonts/Fredoka.ttf"))
	m.layout_for(Vector2(1280, 720))
	m.open()
	assert_true(m.is_open())
	assert_eq(m.current(), "resume")
	assert_eq(m.handle_key(_key("ui_accept")), "resume", "Enter on Resume")
	m.handle_key(_key("ui_down"))
	assert_eq(m.current(), "save")
	assert_eq(m.handle_key(_key("ui_accept")), "save")
	m.handle_key(_key("ui_up"))
	m.handle_key(_key("ui_up"))
	assert_eq(m.current(), "quit", "round to the bottom")
	assert_eq(m.handle_key(_key("ui_accept")), "quit")
	# pages
	for id in ["notebook", "controls", "sound", "cheats"]:
		var i := GameMenu.ENTRIES.map(func(e: Array) -> String: return e[0]).find(id)
		assert_eq(m.choose(i), "", "%s opens a page, nothing for the game to do" % id)
		assert_eq(m.page, id)
		assert_eq(m.handle_key(_key(CityInput.MENU)), "", "Esc: back to the list")
		assert_eq(m.page, "")
	assert_eq(m.handle_key(_key(CityInput.MENU)), "resume", "Esc on the list: resume")
	# the Sound page hands the arrows to the game
	m.show_page("sound")
	assert_eq(m.handle_key(_key("ui_left")), "sound")
	assert_eq(m.sound_rows.size(), AudioSettings.BUSES.size())
	# Load only when there is a save
	m.show_page("")
	m.can_load = false
	var load_i := GameMenu.ENTRIES.map(func(e: Array) -> String: return e[0]).find("load")
	assert_eq(m.choose(load_i), "", "no save: nothing to load")
	m.can_load = true
	assert_eq(m.choose(load_i), "load")


func test_the_controls_page_lists_every_key() -> void:
	var keys := []
	for group in GameMenu.CONTROLS:
		for k in group[1]:
			keys.append(String(k[0]) + " " + String(k[1]))
	var all := " | ".join(keys)
	for want in ["W A S D", "Left Shift", "Left click", "Tab", "H", "E", "1 - 4", "Space", "M", "C", "F1", "Esc",
			"Backspace", "accelerate", "handbrake", "get out", "spin", "pull", "punch"]:
		assert_string_contains(all, want)
	assert_eq(GameMenu.CHEATS, [], "no cheats in this build")


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e
