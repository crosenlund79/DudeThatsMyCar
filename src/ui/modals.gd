class_name Modals
extends RefCounted
## M014 (from main): what is over the street and has the keys - a fistfight's
## dial (M007), a table (M010-M013), a film (M005, M010, M012), the city map
## (M006, M008), the status screen (M006), a talk, the game menu (M012) - and
## the keys routed to it in one fixed order: the first of these that is up
## takes the key and nothing under it sees it. Opening and closing the map,
## the status screen and the menu pause the world under them and give it back
## (with the click that closed them never firing the gun).

var game: Game
## M012: the game menu is open (the world waits under it).
var paused := false
## M006: the city map, or the status screen, is open (the world is paused under it).
var map_open := false
var status_open := false
## The sound level chosen on the menu's Sound page (index into AudioSettings.BUSES).
var sound_row := 0


func _init(p_game: Game) -> void:
	game = p_game


## What has the keys now, in the order they are routed: "fight", "table",
## "film", "map", "status", "talk", "menu", or "" (Danny in the street).
func top() -> String:
	if game.fights.fighting:
		return "fight"
	if game.back_rooms.at_a_table():
		return "table"
	if game.films.playing() and not (game.films.kind == "bird" and game.dialogue.talking != ""):
		return "film"
	if map_open:
		return "map"
	if status_open:
		return "status"
	if game.dialogue.talking != "":
		return "talk"
	if paused:
		return "menu"
	return ""


## A key, a click or a wheel turn not taken by a control on screen.
func route(event: InputEvent) -> void:
	var hud := game.hud
	var dialogue := game.dialogue
	if game.fights.fighting:
		# only Space, for the dial; no walking, shooting, maps or menus mid-fight
		if event.is_action_pressed(CityInput.HANDBRAKE):
			game.fights.press()
		return
	if game.back_rooms.handle_key(event):
		return  # M010, M011: at a table only the table's keys
	if game.films.skip_input(event):
		return  # a film: E, Esc, Space or a click skips it (M012: the Bird's to her question)
	if map_open and event.is_action_pressed(CityInput.RECENTRE):
		hud.city_map.recentre()
		return
	if map_open and (event.is_action_pressed(CityInput.MAP) or event.is_action_pressed(CityInput.MENU)):
		show_map(false)
		return
	if status_open and (event.is_action_pressed(CityInput.STATUS) or event.is_action_pressed(CityInput.MENU)):
		show_status(false)
		return
	if map_open or status_open:
		return  # nothing else while one is open
	if event.is_action_pressed(CityInput.MAP) and not paused and dialogue.talking == "":
		show_map(true)
		return
	if event.is_action_pressed(CityInput.STATUS) and not paused and dialogue.talking == "":
		show_status(true)
		return
	if event.is_action_pressed(CityInput.MENU) and dialogue.talking != "":
		dialogue.end()
	elif paused:
		var what := hud.game_menu.handle_key(event)  # M012: the game menu has the keys
		if what == "sound":
			sound_input(event)
		else:
			menu_action(what)
	elif event.is_action_pressed(CityInput.MENU):
		open_menu(true)
	elif event.is_action_pressed(CityInput.HELP):
		hud.toggle_help()


## M012: the game menu open (Esc) or shut: the world waits under it - the
## clock, the cards, the coppers, every timer - and nothing it does reaches
## the street (the click that closes it never fires the gun).
func open_menu(on: bool) -> void:
	var hud := game.hud
	var save_path := String(game.root.get("save_path"))
	paused = on
	game.root.get_tree().paused = on
	if on:
		hud.game_menu.notebook = Notebook.entries(game.rackets, game.clock.minute)
		hud.game_menu.can_load = save_path != "" and FileAccess.file_exists(save_path)
		hud.game_menu.dev_on = bool(game.prefs.get_pref("dev_tools"))  # M015
		hud.game_menu.dev_categories = game.dev.menu_list() if hud.game_menu.dev_on else []
	hud.set_paused(on)
	hud.show_sound(game.settings, sound_row)
	game.mouse(on)
	if not on:
		game.player.fire_lock = true


## M012: what the game menu asked for ("resume", "save", "load", "quit"; "" nothing).
func menu_action(what: String) -> void:
	var root := game.root
	var save_path := String(root.get("save_path"))
	var hud := game.hud
	match what:
		"resume":
			open_menu(false)
		"save":
			game.save()
			var here_l := game.world.layout_at(game.player.body().global_position)
			var interiors := game.interiors
			var at: String = interiors.current.name if interiors.current != null else (here_l.name if here_l != null else game.layout.name)
			hud.game_menu.say("Saved - Night %d, %s, %s." % [game.rackets.night, game.clock.text(), at] if save_path != ""
				else "Nothing written: this game is not being saved.")
			hud.game_menu.can_load = save_path != "" and FileAccess.file_exists(save_path)
		"load":
			if save_path == "" or not FileAccess.file_exists(save_path):
				return
			root.emit_signal("reload_requested")
			var tree := root.get_tree()
			if tree.current_scene == root:
				tree.paused = false
				tree.reload_current_scene()
		"quit":
			game.save()
			root.get_tree().quit()
		"dev_on":  # M015: the developer tools switched on (a preference)
			game.prefs.set_pref("dev_tools", true)
			hud.game_menu.dev_on = true
			hud.game_menu.dev_categories = game.dev.menu_list()
			hud.game_menu.say("Developer tools switched on - for testing.")
		_:
			if what.begins_with("dev:"):  # M015: a developer tool
				var out := game.dev.run(what.substr(4))
				if bool(out.close):
					if String(out.text) != "":
						hud.show_notice(String(out.text))
				else:
					hud.game_menu.dev_categories = game.dev.menu_list()
					hud.game_menu.say(String(out.text))


## M006: the map of the whole city, on (M) or off (M or Esc). The world waits
## under it: no walking, driving or shooting while it is open.
func show_map(on: bool) -> void:
	var player := game.player
	map_open = on
	game.root.get_tree().paused = on
	var here := game.world.layout_at(player.body().global_position)
	game.hud.show_map(on, player.body().global_position, here.bounds if here != null else game.layout.bounds)
	if on:
		game.rourke_job.on_map()
		update_map()
	# M008: the mouse drags the city map round while it is open
	game.mouse(on)


## M006: how Danny is (C or Esc closes). The world waits meanwhile.
func show_status(on: bool) -> void:
	status_open = on
	game.root.get_tree().paused = on
	game.hud.show_status(on, game.walker.condition)


## The city map's moving parts: Danny (or his car), his own car, the coppers on their feet.
func update_map() -> void:
	var player := game.player
	var mine := game.fleet.my_car()
	var body := player.body()
	var cops := []
	for o in game.police.officers():
		if not o.is_down():
			cops.append(o.body.global_position)
	game.hud.city_map.set_state(body.global_position, game.walker.model.facing if player.on_foot() else player.car.model.heading,
		mine.global_position if mine != null and mine != player.car else Vector2.INF, mine.rotation if mine != null else 0.0, cops)


## On the menu's Sound page: Up / Down choose a sound level, Left / Right change
## it by a tenth (heard at once, kept for next time). True when the key was used.
func sound_input(event: InputEvent) -> bool:
	var settings := game.settings
	var n := AudioSettings.BUSES.size()
	var bus: String = AudioSettings.BUSES[sound_row]
	if event.is_action_pressed("ui_up"):
		sound_row = (sound_row + n - 1) % n
	elif event.is_action_pressed("ui_down"):
		sound_row = (sound_row + 1) % n
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		var step := 0.1 if event.is_action_pressed("ui_right") else -0.1
		settings.set_volume(bus, snappedf(settings.volume[bus] + step, 0.1))
		if String(game.root.get("settings_path")) != "":
			settings.save_settings()
	else:
		return false
	game.hud.show_sound(settings, sound_row)
	return true


## M010: while the drowsiness must keep out of the way (talk, the opening or
## the cafe's film, the maps, a fight, a table).
func drowsy_held() -> bool:
	var films := game.films
	return game.dialogue.talking != "" or films.of("opening") != null or map_open or status_open or game.fights.fighting \
		or game.back_rooms.at_a_table() or films.of("cafe") != null


## M012: what Danny is in the middle of, for whoever might call out to him.
func busy() -> Dictionary:
	return {"talking": game.dialogue.talking != "", "busy": game.back_rooms.at_a_table() or not game.player.seat.is_empty(),
		"film": game.films.playing() or game.last_song.scene != "", "fighting": game.fights.fighting,
		"menu": paused or map_open or status_open}
