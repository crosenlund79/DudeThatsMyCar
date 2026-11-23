extends "res://tests/support/city_test.gd"
## M014 golden master: representative courses of play driven through the real
## scene, each ending in a snapshot of the game's state (money and the books,
## the jobs, memories and talk, the cars, Danny, the clock, the districts, the
## tables, the films). The snapshots were recorded on the M013 code before the
## M014 refactor (tests/golden/m013/) and every later build must reproduce them
## exactly - the refactor changes the architecture, never the game.
##
## Record (only ever on the reference build):
##   GOLDEN_RECORD=1 godot --headless --path . --fixed-fps 60 -s addons/gut/gut_cmdln.gd \
##     -gtest=res://tests/integration/test_golden_master.gd
## Every random generator the game randomizes in play is seeded here, so two
## runs of the same build give the same snapshots (checked when recording).

const GOLDEN := "res://tests/golden/m013/"
const SAVE := "user://test_golden_master.json"

var _record := OS.get_environment("GOLDEN_RECORD") == "1"


func before_each() -> void:
	await super()
	_seed()


func after_each() -> void:
	super()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


## The generators the game randomizes in play, fixed.
func _seed() -> void:
	main.back_rooms.wheel.rng.seed = 1301
	main.back_rooms.wheel_patrons.rng.seed = 1302
	main.back_rooms.room_life.rng.seed = 1303
	main.back_rooms.slot_rng.seed = 1304
	main.back_rooms.react_rng.seed = 1305
	main.back_rooms.taunt_rng.seed = 1306


## A new scene (optionally loading SAVE, optionally with the opening).
func _rebuild(load_save: bool, opening := false) -> void:
	if load_save:
		main.save_path = SAVE
		main.save_game()
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE if load_save else ""
	main.settings_path = ""
	main.opening_enabled = opening
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	if not load_save:
		for id in VoiceLines.LINES:
			main.voice_lines.mark(id)
	_seed()
	await wait_physics_frames(3)


# ------------------------------------------------------------------ the snapshot

func _r(x: float, places := 2) -> float:
	return snappedf(x, pow(10.0, -places))


func _v(p: Vector2) -> Array:
	return [_r(p.x), _r(p.y)]


## JSON-like copy with floats rounded (Vector2 as [x, y]).
func _norm(x: Variant) -> Variant:
	match typeof(x):
		TYPE_DICTIONARY:
			var out := {}
			for k in x:
				out[str(k)] = _norm(x[k])
			return out
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			var out := []
			for e in x:
				out.append(_norm(e))
			return out
		TYPE_FLOAT:
			return _r(x, 3)
		TYPE_INT:
			return float(x)  # JSON keeps numbers as floats
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return _v(Vector2(x))
		TYPE_STRING_NAME:
			return String(x)
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return x
	return str(x)


## The save file as the game writes it, without its format version.
func _save_now() -> Dictionary:
	var keep: String = main.save_path
	main.save_path = SAVE
	main.save_game()
	main.save_path = keep
	var d := SaveGame.read(SAVE)
	d.erase("version")
	return d


func _snapshot() -> Dictionary:
	var w: Walker = walker()
	var p: PlayerController = player()
	var cars := []
	for i in main.fleet.cars.size():
		var c: Car = main.fleet.cars[i]
		cars.append({"id": main.fleet.ids[i], "pos": _v(c.global_position), "rot": _r(c.global_rotation, 3),
			"away": c.has_meta("away"), "cargo": String(c.get_meta("cargo", "")), "stolen": main.fleet.thefts.is_stolen(i)})
	var camera := "other"
	if main.camera.target == w:
		camera = "walker"
	elif main.camera.target is Car:
		camera = "car"
	elif main.films.of("cafe") != null and main.camera.target == main.films.of("cafe").rig:
		camera = "cafe_film"
	elif main.films.of("bird") != null and main.camera.target == main.films.of("bird").rig:
		camera = "bird_film"
	var ready: Array = main.world.ready_ids()
	ready.sort()
	var s := {
		"save": _save_now(),
		"rackets": main.rackets.to_dict(),
		"voices": main.voice_lines.to_dict(),
		"poker": main.back_rooms.poker.to_dict(),
		"poker_seated": main.back_rooms.poker.seated(),
		"poker_purses": main.back_rooms.poker.players_money(),
		"slots": main.back_rooms.slot_machines.map(func(m: SlotMachine) -> Dictionary: return m.to_dict()),
		"roulette": {"for_save": main.back_rooms.roulette.for_save(), "bets": main.back_rooms.roulette.bets, "phase": main.back_rooms.wheel.phase,
			"number": main.back_rooms.wheel.number},
		"danny": {"condition": w.condition.to_dict(), "pos": _v(w.global_position), "facing": _r(w.model.facing, 3),
			"on_foot": p.on_foot(), "car": main.fleet.ids[main.fleet.cars.find(p.car)] if p.car != null else "",
			"sitting": not p.seat.is_empty(), "down": w.down},
		"gun": {"ammo": main.armoury.pistol.ammo, "spare": main.armoury.pistol.spare, "drawn": main.armoury.pistol.is_drawn(),
			"thompson": main.armoury.thompson != null},
		"cars": cars,
		"thefts": [main.fleet.theft_incidents, main.fleet.thefts_witnessed],
		"ward_out": main.casualties.ward_out,
		"rival": main.rival.to_dict(),
		"night": main.rackets.night,
		"minute": _r(main.clock.minute, 2),
		"world": {"current": main.world.current, "ready": ready},
		"room": main.interiors.current.id if main.interiors.current != null else "",
		"talking": main.dialogue.talking,
		"page": {"text": String(main.dialogue.page.get("text", "")),
			"options": (main.dialogue.page.get("options", []) as Array).map(func(o: Dictionary) -> String: return String(o.id))},
		"incidents": main.incidents.to_dict(),
		"weather": {"state": main.weather.state_name(), "rain": _r(main.weather.rain_strength(), 3), "fog": _r(main.weather.fog, 3)},
		"films": {"opening": main.films.of("opening") != null, "cafe": main.films.of("cafe") != null, "bird": main.films.of("bird") != null,
			"bird_scene": main.last_song.scene},
		"hud_visible": main.hud.visible,
		"camera": camera,
		"collapses": main.casualties.collapses,
		"moments": main.night.moments,
		"fighting": main.fights.fighting,
		"paused": main.modals.paused,
		"views": {"poker": main.hud.poker_view.is_open(), "roulette": main.hud.roulette_view.is_open(),
			"slot": main.hud.slot_view.is_open()},
	}
	return _norm(s)


## Flattens a snapshot into path -> value for a readable comparison.
func _flat(x: Variant, path: String, out: Dictionary) -> void:
	if x is Dictionary:
		if (x as Dictionary).is_empty():
			out[path] = "{}"
		for k in x:
			_flat(x[k], path + "/" + str(k), out)
	elif x is Array:
		if (x as Array).is_empty():
			out[path] = "[]"
		for i in (x as Array).size():
			_flat(x[i], path + "[%d]" % i, out)
	else:
		out[path] = x


## Records the snapshot (reference build) or compares it with the recording.
func _check(case_name: String) -> void:
	var snap := _snapshot()
	var path := GOLDEN + case_name + ".json"
	if _record:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN))
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify(snap, "\t", true))
		f.close()
		pass_test("recorded " + case_name)
		return
	assert_true(FileAccess.file_exists(path), "a recording for " + case_name)
	if not FileAccess.file_exists(path):
		return
	var want: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var a := {}
	var b := {}
	_flat(_norm(want), "", a)
	_flat(_norm(JSON.parse_string(JSON.stringify(snap))), "", b)
	var diffs := []
	for k in a:
		if not b.has(k):
			diffs.append("%s: %s -> (missing)" % [k, a[k]])
		elif a[k] != b[k]:
			diffs.append("%s: %s -> %s" % [k, a[k], b[k]])
	for k in b:
		if not a.has(k):
			diffs.append("%s: (missing) -> %s" % [k, b[k]])
	assert_eq(diffs.size(), 0, "%s as recorded on M013; %d differences: %s" % [case_name, diffs.size(), "\n".join(diffs.slice(0, 25))])


# ------------------------------------------------------------------ helpers

func _key(code: Key, pressed: bool = true) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.pressed = pressed
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _action(action: String) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	main._unhandled_input(e)
	await wait_physics_frames(1)


func _collect(plan: String, who: String) -> void:
	await talk_to(plan, who)
	await answer_with("protection")
	await answer_with("ask")
	await press_e()


func _sleep() -> void:
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)


func _street(l: DistrictLayout, street_name: String) -> Rect2:
	for st in l.streets:
		if st.name == street_name:
			return st.rect
	return Rect2()


func _until_wheel(phase: int, fresh := true) -> void:
	if fresh:
		for i in 3000:
			if main.back_rooms.wheel.phase != phase:
				break
			await wait_physics_frames(1)
	for i in 3000:
		if main.back_rooms.wheel.phase == phase:
			return
		await wait_physics_frames(1)


func _until_paid() -> void:
	for f in 600:
		if main.hud.slot_view.phase == "paid":
			return
		await wait_physics_frames(1)


# ------------------------------------------------------------------ the cases

## A new game, straight into the night; and one with the opening, watched a
## little and skipped. The new game starts from a scene built here, like every
## other case: the very first scene in a Godot process gets one frame of the
## night clock less than any later one (M013 and M014 alike), so the scene
## made before the test gave a different minute when the suite ran in one
## process. new_game.json was recorded again on the M013 code with this start.
func test_new_game_and_the_opening() -> void:
	await _rebuild(false)
	await wait_physics_frames(10)
	_check("new_game")
	await _rebuild(false, true)
	await wait_physics_frames(90)
	_check("opening_running")
	await _key(KEY_ESCAPE)
	for i in 600:
		await wait_physics_frames(1)
		if main.films.of("opening") == null:
			break
	await wait_physics_frames(5)
	_check("opening_skipped")


## Two nights of the ward's ordinary business: the rye from Sal to Augie,
## protection from the club and the grocery, Rourke's envelope (straight the
## first night, skimmed the second), the ward living through the day, the talk
## going round; saved and loaded between.
func test_two_nights_of_business_and_talk() -> void:
	main.rackets.money = 1500
	await talk_to("barber_shop", "sal")
	await answer_with("buy_all")
	await answer_with("bye")
	await talk_to("copper_owl", "augie")
	await answer_with("sell")
	await press_e()
	await _collect("copper_owl", "augie")
	await _collect("grocery", "novak")
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	await answer_with("top_up")
	await press_e()
	_check("economy_night1")
	await _sleep()
	_check("economy_dawn2")
	await _collect("copper_owl", "augie")
	await _collect("grocery", "novak")
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	await answer_with("skim")
	await press_e()
	await _rebuild(true)
	_check("economy_night2_loaded")
	await _sleep()
	await _sleep()
	_check("economy_night4")


## Freight Doesn't Walk, talked round: Leon's job taken, Dutch tells, Leon
## squares it, Walt hears it, the fee collected (once).
func test_an_independent_job() -> void:
	main.rackets.money = 900
	walker().place(main.world.layouts.yards.interiors.filter(func(p: InteriorPlan) -> bool: return p.id == "dispatch_office")[0].outside_door(0, 60.0), PI / 2)
	main.world.load_now("yards")
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	var office: InteriorPlan = main.interiors.plan_named("dispatch_office")
	await walk_in_to(office, "leon")
	await press_e()
	await answer_with("freight_hear")
	await answer_with("freight_accept")
	await answer_with("bye")
	_check("freight_accepted")
	var dutch_at: Vector2 = (main.world.layouts.yards as DistrictLayout).contacts[0].pos
	walker().place(dutch_at + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	await answer_with("freight_ask")
	await answer_with("bye")
	await walk_in_to(office, "leon")
	await press_e()
	await answer_with("freight_square")
	await answer_with("bye")
	var shed: InteriorPlan = main.interiors.plan_named("freight_shed")
	await walk_in_to(shed, "walt")
	await press_e()
	await answer_with("walt_squared")
	await answer_with("bye")
	await wait_physics_frames(3)
	await walk_in_to(office, "leon")
	await press_e()
	await answer_with("bye")
	await walk_in_to(office, "leon")
	await press_e()
	await answer_with("bye")
	_check("freight_done")


## A car driven into Halloran Square, saved at the wheel and loaded: back
## behind it; a stolen car kept taken; then driven back over the border.
func test_cars_kept_and_a_border_crossed() -> void:
	var h: DistrictLayout = main.world.layouts.halloran
	var marlowe := _street(h, "Marlowe Avenue")
	var spot := Vector2(marlowe.end.x - 700.0, marlowe.get_center().y + 30.0)
	walker().place(spot + Vector2(0, -40), 0.0)  # there first, or the streamer lets the square go again
	main.world.load_now("halloran")
	var car := roadster()
	await park(car, spot, 0.0)
	await seat_in(car)
	cmd = PlayerCommand.make(Vector2(0, -1))
	await wait_physics_frames(40)
	cmd = PlayerCommand.new()
	await wait_physics_frames(30)
	_check("car_before_save")
	await _rebuild(true)
	_check("car_after_load")
	car = player().car
	var y := _street(main.layout, "Marlowe Avenue").get_center().y + 30.0
	for i in 1500:
		var to := Vector2(STREETCAR_STOP.x - 120.0, y) - car.global_position
		var steer := clampf(angle_difference(car.global_rotation, to.angle()) * 2.0, -1.0, 1.0)
		cmd = PlayerCommand.make(Vector2(steer, -1.0 if car.speed() < 200.0 else 0.0))
		await wait_physics_frames(1)
		if to.length() < 80.0:
			break
	cmd = PlayerCommand.make(Vector2(0, 1))
	await wait_physics_frames(80)
	cmd = PlayerCommand.new()
	await wait_physics_frames(5)
	_check("border_crossed")


## The back rooms' books: a round at Leo's wheel, the three machines with a
## hold and a respin, a few hands at the card table and leaving it.
func test_the_house_books() -> void:
	main.rackets.money = 5000
	main.clock.set_time(24 * 60.0)
	walker().place(RiversideInteriors.ROULETTE_SPOT + Vector2(0, 30), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(5)
	await _until_wheel(RouletteTable.Phase.OPEN)
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	main.hud.roulette_view.pick_chip(3)
	main.back_rooms.bet("black", 100)
	main.hud.roulette_view.pick_chip(1)
	main.back_rooms.bet("straight:23", 10)
	main.back_rooms.bet("dozen:2", 25)
	await _until_wheel(RouletteTable.Phase.RESULT, false)
	await wait_physics_frames(10)
	_check("wheel_paid")
	await _key(KEY_ESCAPE)
	for i in 3:
		walker().place(RiversideInteriors.SLOTS[i] + Vector2(0, 32), -PI / 2)
		await wait_physics_frames(3)
		await press_e()
		for pull in 4:
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
			await _until_paid()
			var m: SlotMachine = main.back_rooms.slot_machines[i]
			if m.hold_offered:
				await _key(KEY_1)
				await _key(KEY_SPACE)
				await _key(KEY_SPACE, false)
				await _until_paid()
		await _key(KEY_S)
		await _key(KEY_ESCAPE)
	_check("machines_played")
	var back: InteriorPlan = main.interiors.view_of("back_room").plan
	walker().place(back.spots[0].pos, -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	var pv: PokerView = main.hud.poker_view
	pv.think = Vector2(0.05, 0.08)
	pv._rng.seed = 1307  # the card players' thinking time (a random seed in play)
	await _key(KEY_1)
	for f in 9000:
		var t: Holdem = main.back_rooms.poker.table
		if pv.pacing.waiting():
			await _key(KEY_SPACE)
			await _key(KEY_SPACE, false)
		elif t.running() and t.to_act == main.back_rooms.poker.danny:
			await _key(KEY_2)  # check or call
		await wait_process_frames(1)
		if main.back_rooms.poker.hands >= 3:
			break
	_check("poker_three_hands")
	await _key(KEY_ESCAPE)
	await _key(KEY_ENTER)
	await wait_physics_frames(3)
	_check("poker_left")


## Rourke's café job to the end, its film played through; and the Bird's last
## song, her film skipped to her question and the question walked away from.
func test_films_played_and_skipped() -> void:
	main.rackets.money = 2000
	await talk_to("copper_owl", "rourke")
	await answer_with("cafe")
	await answer_with("cafe_accept")
	await press_e()
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	await answer_with("parcel")
	await press_e()
	var h: DistrictLayout = main.world.layouts.halloran
	var car: Vector2 = h.cafe_point("car").pos
	walker().place(car + Vector2(0, -34), PI / 2)
	main.camera.snap_to(walker())
	main.world.load_now("halloran")
	main.clock.set_time(22 * 60.0 + 30.0)
	await wait_physics_frames(4)
	await press_e()
	var bench: Vector2 = h.cafe_point("bench").pos
	var seats: Array = main.districts.seats_near().filter(func(s: Dictionary) -> bool: return (s.pos as Vector2).distance_to(bench) < 4.0)
	walker().place(seats[0].stand, 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(2)
	await press_e()
	cmd = PlayerCommand.make(Vector2.ZERO, false, true)
	for i in 600:
		await wait_physics_frames(1)
		if main.films.of("cafe") != null:
			break
	cmd = PlayerCommand.new()
	await wait_physics_frames(60 * 6)
	_check("cafe_film_running")
	for i in 60 * 10:
		await wait_physics_frames(1)
		if main.films.of("cafe") == null:
			break
	await wait_physics_frames(5)
	_check("cafe_film_done")
	if not player().seat.is_empty():
		await press_e()  # up from the bench
	# the Bird
	main.callouts_enabled = true
	main.clock.set_time(LastSong.LAST_SONG + 1.0)
	walker().place(Vector2(2290, 380), -PI / 2)
	main.camera.snap_to(walker())
	for i in 30:
		await wait_physics_frames(1)
		if main.last_song.scene != "":
			break
	var bird: Walker = main.bird_show.bird
	for i in 240:
		await wait_physics_frames(1)
		if bird.global_position.distance_to(main.last_song.seat()) < 5.0:
			break
	walker().place(main.last_song.seat() + Vector2(0, 34), -PI / 2)
	await wait_physics_frames(3)
	await press_e()
	await wait_physics_frames(30)
	_check("bird_film_running")
	await _key(KEY_ESCAPE)
	for i in 1200:
		await wait_physics_frames(1)
		if main.dialogue.talking == "bird_scene":
			break
	await press_e()
	for i in 600:
		await wait_physics_frames(1)
		if main.films.of("bird") == null:
			break
	await wait_physics_frames(5)
	_check("bird_film_skipped")


## M014: the real saves written by each milestone's own code (M003-M013,
## tests/fixtures/saves/), each loaded into a new scene and snapshotted - the
## same snapshot as loading them with the M013 build (recorded there).
const FIXTURES := ["m003", "m005", "m006", "m007", "m008", "m009", "m010", "m011", "m012", "m013"]


func _load_fixture(fixture: String) -> void:
	remove_child(main)
	main.free()
	var text := FileAccess.get_file_as_string("res://tests/fixtures/saves/%s.json" % fixture)
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = false
	main.save_path = SAVE
	main.settings_path = ""
	main.opening_enabled = true  # a loaded game never plays the opening
	main.quiet_streets = true
	add_child_autofree(main)
	main.street.clear()
	_seed()
	await wait_physics_frames(10)


func test_historical_saves_load_as_before() -> void:
	for fixture in FIXTURES:
		await _load_fixture(fixture)
		_check("loaded_" + fixture)
