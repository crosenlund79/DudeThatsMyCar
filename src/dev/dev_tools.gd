class_name DevTools
extends RefCounted
## M015: the developer tools - for testing the game, not part of it. Shown in
## the game menu (Developer tools) once switched on there (a preference that
## holds across games). Each tool goes through the game's own systems (the
## night's clock with everything that moves with it, the fleet, the films,
## the jobs' own models) and says what it did; nothing is written to the save
## until the game saves as it always does. A tool that throws something away
## (a job started over, what people remember) is marked and asks first.
##
## A new tool: one entry in the list its category builds below - {id, name,
## "ask" (a warning: asked twice) or "", run: Callable() -> Dictionary
## {text, close (the menu shuts: the tool needs the street)}}.

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## The categories and their tools, in the menu's order:
## [{name, tools: [{id, name, ask, run}]}].
func catalogue() -> Array:
	return [
		{"name": "Money", "tools": _money()},
		{"name": "Time", "tools": _time()},
		{"name": "Weather", "tools": _weather()},
		{"name": "Go to a district", "tools": _districts()},
		{"name": "Go to a place", "tools": _places()},
		{"name": "Go into a room", "tools": _rooms()},
		{"name": "Cars", "tools": _cars()},
		{"name": "Danny", "tools": _danny()},
		{"name": "Police", "tools": _police()},
		{"name": "Jobs and errands", "tools": _jobs()},
		{"name": "Films", "tools": _films()},
		{"name": "The tables", "tools": _tables()},
		{"name": "People", "tools": _people()},
		{"name": "Developer tools", "tools": [_tool("dev_off", "Switch the developer tools off", func() -> Dictionary:
			game.prefs.set_pref("dev_tools", false)
			game.hud.game_menu.dev_on = false
			return _said("Developer tools switched off."))]},
	]


## The catalogue as the menu shows it (no code in it): [{name, tools: [{id, name, ask}]}].
func menu_list() -> Array:
	var out := []
	for cat in catalogue():
		out.append({"name": cat.name, "tools": (cat.tools as Array).map(func(t: Dictionary) -> Dictionary:
			return {"id": t.id, "name": t.name, "ask": t.ask})})
	return out


## Runs tool `id`. Returns {text, close}.
func run(id: String) -> Dictionary:
	for cat in catalogue():
		for t in cat.tools:
			if t.id == id:
				var out: Dictionary = (t.run as Callable).call()
				out.merge({"text": "", "close": false})
				return out
	return {"text": "No such tool: " + id, "close": false}


## Whether tool `id` asks before it runs ("" = it does not; else the warning).
func asks(id: String) -> String:
	for cat in catalogue():
		for t in cat.tools:
			if t.id == id:
				return String(t.ask)
	return ""


static func _tool(id: String, name: String, run: Callable, ask := "") -> Dictionary:
	return {"id": id, "name": name, "run": run, "ask": ask}


static func _said(text: String, close := false) -> Dictionary:
	return {"text": text, "close": close}


# ------------------------------------------------------------------ money

func _money() -> Array:
	return [
		_tool("money_plus_10", "Add $10", func() -> Dictionary: return _give(1000)),
		_tool("money_plus_100", "Add $100", func() -> Dictionary: return _give(10000)),
		_tool("money_minus_10", "Take $10 away", func() -> Dictionary: return _give(-1000)),
		_tool("money_empty", "Empty his pockets", func() -> Dictionary: return _give(-game.rackets.money),
			"Every cent he carries goes."),
	]


func _give(cents: int) -> Dictionary:
	var r := game.rackets
	r.money = maxi(0, r.money + cents)
	game.show_purse()
	return _said("Money: %s in his pocket." % Rackets.dollars(r.money))


# ------------------------------------------------------------------ time

func _time() -> Array:
	return [
		_tool("time_plus_30", "Half an hour later", func() -> Dictionary: return _later(30.0)),
		_tool("time_plus_60", "An hour later", func() -> Dictionary: return _later(60.0)),
		_tool("time_to_late", "On to half past three", func() -> Dictionary:
			return _later(maxf(0.0, 27 * 60 + 30.0 - game.clock.minute))),
		_tool("time_new_night", "Sleep: the next night begins", func() -> Dictionary:
			game.modals.open_menu(false)
			game.night.sleep()
			return _said("Night %d." % game.rackets.night, true),
			"He goes to bed: the rest of tonight is skipped."),
	]


func _later(minutes: float) -> Dictionary:
	game.night.pass_minutes(minutes)
	return _said("The time: %s." % game.clock.text())


# ------------------------------------------------------------------ weather

func _weather() -> Array:
	var out := []
	for w in [["clear", "Clear"], ["rain", "Rain"], ["fog", "Fog"], ["rain_fog", "Rain and fog"]]:
		var state: String = w[0]
		out.append(_tool("weather_" + state, String(w[1]) + " all night", func() -> Dictionary:
			game.weather.force(state)
			return _said("The weather: %s, held all night." % String(w[1]).to_lower())))
	out.append(_tool("weather_own", "The night's own weather", func() -> Dictionary:
		game.weather.force("")
		return _said("The weather goes its own way again.")))
	return out


# ------------------------------------------------------------------ going places

func _districts() -> Array:
	var out := []
	for id in game.world.order:
		var l: DistrictLayout = game.world.layouts[id]
		out.append(_tool("go_district_" + String(id), l.name, func() -> Dictionary: return go_to(String(id) + "/spawn")))
	return out


## The places worth going to: every named place of every district.
func _places() -> Array:
	var out := []
	for pid in game.locations.ids():
		if String(pid).contains("/place/"):
			out.append(_tool("go_" + String(pid), _words(String(pid)), func() -> Dictionary: return go_to(String(pid))))
	return out


## Every room in the city.
func _rooms() -> Array:
	var out := []
	for pid in game.locations.ids():
		if String(pid).contains("/room/"):
			out.append(_tool("go_" + String(pid), _words(String(pid)), func() -> Dictionary: return go_to(String(pid))))
	return out


static func _words(pid: String) -> String:
	var parts := pid.split("/")
	return "%s  (%s)" % [parts[parts.size() - 1].replace("_", " ").capitalize(), parts[0].capitalize()]


## Danny (on foot, or in his car) put down at place `pid`: its district built
## first, the rooms told where he is, the camera with him.
func go_to(pid: String) -> Dictionary:
	if not game.locations.has(pid):
		return _said("No such place: " + pid)
	var at := game.locations.at(pid)
	var d := CityLocations.district_of(pid)
	if not game.world.is_ready(d):
		game.world.load_now(d)
	var player := game.player
	if player.car != null:
		player.car.place(Transform2D(game.locations.facing(pid), at))
	else:
		game.walker.place(at, game.locations.facing(pid))
	game.interiors.update_player(at if player.car == null else Vector2.INF)
	game.interiors.snap()
	game.camera.snap_to(player.body())
	game.modals.open_menu(false)
	return _said("Went to %s." % _words(pid), true)


# ------------------------------------------------------------------ cars

func _cars() -> Array:
	return [
		_tool("car_mine_here", "His own sedan here", func() -> Dictionary: return _car_here(game.fleet.my_car(), "His sedan")),
		_tool("car_lefty_here", "Lefty's speedster here", func() -> Dictionary:
			return _car_here(game.leftys_car.car(), "Lefty's speedster")),
		_tool("cars_parked", "Every car back at its parking place", func() -> Dictionary:
			var fleet := game.fleet
			for i in fleet.cars.size():
				var c := fleet.cars[i]
				if c == game.player.car:
					continue
				c.place(Transform2D(float(fleet.specs[i].rot), fleet.specs[i].pos))
				fleet.put_away(c, not game.world.is_ready(game.world.district_at(c.global_position)))
			return _said("Every car (but the one he sits in) is back at its parking place. (Cars take no damage in this build: nothing to repair.)"),
			"Every car he moved goes back where its owner parked it."),
	]


func _car_here(c: Car, words: String) -> Dictionary:
	if c == null:
		return _said("There is no such car.")
	if c == game.player.car:
		return _said("He is sitting in it.")
	var me := game.player.body().global_position
	for off in [Vector2(70, 0), Vector2(-70, 0), Vector2(0, 60), Vector2(0, -60), Vector2(110, 40), Vector2(-110, -40)]:
		var p: Vector2 = me + off
		if game.fleet.can_stand(c, p):
			if c.has_meta("away"):
				game.fleet.put_away(c, false)
			c.place(Transform2D(0.0, p))
			return _said("%s is beside him." % words)
	return _said("No room for a car here.")


# ------------------------------------------------------------------ Danny

func _danny() -> Array:
	return [
		_tool("danny_heal", "Patch him up", func() -> Dictionary:
			game.walker.condition.heal_all()
			return _said("Not a scratch on him.")),
		_tool("danny_ammo", "Fill his guns", func() -> Dictionary:
			var a := game.armoury
			for g in [a.pistol, a.thompson]:
				if g != null:
					g.ammo = g.rules.magazine
					if g.spare >= 0:
						g.spare = maxi(g.spare, g.rules.magazine * 3)
			return _said("A full magazine, and rounds to spare%s." % (" - the Thompson's too" if a.thompson != null else ""))),
	]


# ------------------------------------------------------------------ police

func _police() -> Array:
	return [
		_tool("police_after", "A copper comes after him", func() -> Dictionary:
			var me := game.player.body().global_position
			var n := 0
			for o in game.police.officers():
				if o.hear_gunshot(me, 2000.0):
					n += 1
			game.modals.open_menu(false)
			return _said("%d beat cop%s heard a shot where he stands." % [n, "" if n == 1 else "s"], true)),
		_tool("police_off", "Call the police off", func() -> Dictionary:
			for o in game.police.officers():
				if not o.is_down():
					o.reset()
			return _said("Every beat cop is back on his round, nothing on his mind.")),
	]


# ------------------------------------------------------------------ jobs and errands

func _jobs() -> Array:
	return [
		_tool("job_rourke_again", "Rourke's job about Lefty: start it over", func() -> Dictionary:
			game.rackets.job = RourkeJob.new()
			return _said("Rourke will offer the Lindqvist job again (Lefty as he is now)."),
			"Everything done in Rourke's job about Lefty is forgotten."),
		_tool("job_cafe_again", "Rosie's Cafe: start it over", func() -> Dictionary:
			game.rackets.cafe = CafeJob.new()
			game.rackets.parcels = 0
			game.rackets.parcel_wanted = false
			return _said("Rourke will offer the cafe job again."),
			"Everything done in the cafe job is forgotten (a wreck already in the street stays)."),
		_tool("job_freight_again", "Freight Doesn't Walk: start it over", func() -> Dictionary:
			game.rackets.freight = FreightJob.new()
			return _said("Leon at North Branch Freight has his trouble again."),
			"Everything done in the freight job is forgotten."),
		_tool("job_bird_again", "After the Last Song: possible again", func() -> Dictionary:
			game.rackets.bird_scene = ""
			game.rackets.bird_scene_night = -1
			return _said("The Bird may ask him to stay again, after half past one."),
			"What Danny told the Bird is forgotten."),
		_tool("job_lefty_car_forget", "Lefty forgets about his car", func() -> Dictionary:
			game.rackets.lefty_car = LeftysCar.new()
			if game.rival != null:
				game.rival.brain.grudge = false
			return _said("Lefty knows nothing about his car (wherever it stands)."),
			"What Lefty knows about his car is forgotten."),
	]


# ------------------------------------------------------------------ films

func _films() -> Array:
	return [
		_tool("film_opening", "Play the opening", func() -> Dictionary:
			game.modals.open_menu(false)
			game.films.start_opening(game.ward_plan("copper_owl"))
			return _said("", true)),
		_tool("film_stop", "Stop the film that is playing", func() -> Dictionary:
			var f := game.films.current
			if f == null:
				return _said("No film is playing.")
			f.skip()
			return _said("Skipped.")),
	]


# ------------------------------------------------------------------ the tables

func _tables() -> Array:
	return [
		_tool("tables_show", "How the tables stand", func() -> Dictionary: return _said(_tables_text())),
		_tool("tables_wheel_round", "The wheel: Leo opens a fresh round", func() -> Dictionary:
			var back := game.back_rooms.wheel.begin_night()
			game.rackets.money += back
			game.show_purse()
			return _said("A fresh round at the wheel%s." % (" (%s back to him)" % Rackets.dollars(back) if back > 0 else ""))),
		_tool("tables_lamps_out", "The machines: lamps out, holds off", func() -> Dictionary:
			for m in game.back_rooms.slot_machines:
				if not m.pending:
					m.hold_offered = false
					m.held = [false, false, false]
			return _said("Every machine's HOLD lamps are out.")),
	]


func _tables_text() -> String:
	var b := game.back_rooms
	var w := b.wheel
	var lines := ["The wheel: %s, pace %s, round %d, last numbers %s." % [w.phase_name(), RouletteRules.pace_name(w.pace),
		w.rounds, str(b.roulette.history.slice(0, 6)) if "history" in b.roulette else "-"]]
	for m in b.slot_machines:
		lines.append("%s: stake %s, lamps %s, held %s." % [m.rules.title, Rackets.dollars(m.stake), "lit" if m.hold_offered else "out", str(m.held)])
	lines.append("The cards: %s stakes, %d hands tonight." % [String(PokerNight.LEVELS[b.poker.level].name), b.poker.hands])
	return "  ".join(lines)


# ------------------------------------------------------------------ people

func _people() -> Array:
	return [
		_tool("people_memories", "What people remember of him", func() -> Dictionary: return _said(_memories_text())),
		_tool("people_rourke_trust", "Rourke trusts him again", func() -> Dictionary:
			game.rackets.boss.trust = 80
			game.rackets.boss.patience = 3
			return _said("Rourke's trust 80, his patience 3.")),
		_tool("people_forget", "Everybody forgets Danny's doings", func() -> Dictionary:
			game.rackets.memory = Memories.new()
			game.rackets.rumours = Rumours.new()
			return _said("Nobody remembers a thing about him, and nobody is talking."),
			"Every memory of Danny and all the talk going round are thrown away."),
	]


func _memories_text() -> String:
	var r := game.rackets
	var parts := []
	for who in ["rourke", "augie", "sal", "novak", "eddie", "lefty", "bird", "dutch", "feeney", "leon", "quilty"]:
		var att := r.memory.attitude(who, r.night)
		if not att.is_empty():
			parts.append("%s: %s" % [who.capitalize(), str(att)])
	return "Nobody remembers anything about him." if parts.is_empty() else "  ".join(parts)
