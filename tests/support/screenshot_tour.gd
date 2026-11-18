extends SceneTree
## Renders the neighbourhood and saves screenshots (needs a display, e.g.
## xvfb-run; not part of the automated tests):
##   godot --path . -s tests/support/screenshot_tour.gd -- <output dir> [shot names...]
## Shots: street (the M001 starting view at the streetcar stop), walk (on foot by the roadster), drive
## (driving down Marlowe Avenue), garage, river, alley, wide, shoot (firing at
## the Copper Owl, captured on the muzzle flash), beat / pursuit (the officer),
## story (the M002 sequence: shots, the officer, the getaway, the alley, lost
## him), steer (M003: the roadster's front wheels at full lock, standing and turning),
## club / club_door / barber / grocery / eddie (M003 interiors and talk),
## home (where the night begins), wake (the next evening fading in),
## cars (M004: the cars in six headings, lights off), grocery_door,
## grocery_marker (at Novak's door), drive_markers (markers from the car),
## opening (M005: the monologue over the ward, six moments and the hand-over),
## rourke (M005: settling up at his table), sound_levels (M005: the pause screen),
## bird / bird_talk (M006: the Bird singing; interrupted), lefty / gunfight (M006: Lefty
## Moran outside Doyle's Garage; shooting, then shot down: lefty_down), ward_map, vet, status, morgue (M006), fight / fight_landed (M007),
## weather_clear / weather_rain / weather_fog / weather_rain_fog / fog_alley / fog_headlights, drowsy, map_labels,
## map_medium, ping, truck_found, park / sitting, back_room / poker_game, thompson,
## cafe_packard / cafe_blast / cafe_aftermath, emergency (M010),
## wheels / wheels_lock (M009: the front tyres, straight and at full lock), dump_truck, school_bus,
## incident / incident_broken_up / incident_stop, dutch / crate, feeney / film_can (M009).

var main: Node2D
var out_dir := "user://shots"
var cmd := PlayerCommand.new()
var _click := false
var _flash_seen := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	main = load("res://src/main/main.tscn").instantiate()
	main.save_path = ""
	main.settings_path = ""
	main.opening_enabled = false
	main.command_source = func(_c: PlayerController) -> PlayerCommand:
		var out := PlayerCommand.make(cmd.move, cmd.interact, cmd.handbrake, cmd.aim, _click)
		out.fire = out.fire or cmd.fire  # M010: held down (the Thompson)
		out.sprint = cmd.sprint
		_click = false
		return out
	root.add_child(main)
	var shots: Array = args.slice(1) if args.size() > 1 else ["street", "walk", "drive", "garage", "river", "alley", "hotel"]
	_run.call_deferred(shots)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame


func _shot(name: String, settle: bool = true) -> void:
	if settle:
		await _frames(3)
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("saved ", name)


func _teleport_walker(p: Vector2, facing: float) -> void:
	main.walker.place(p, facing)
	main.camera.snap_to(main.walker)
	cmd = PlayerCommand.make(Vector2.ZERO, false, false, p + Vector2.from_angle(facing) * 80)


func _run(shots: Array) -> void:
	await _frames(20)
	if main.hud.help_panel.visible:
		main.hud.toggle_help()  # the controls card would cover the view
	for s in shots:
		match s:
			"street":
				# the M001 / M002 starting view at the streetcar stop (since M003 the night begins at home: see "home")
				_teleport_walker(Vector2(2350, 600), PI * 0.3)
				await _frames(30)
				await _shot("street")
			"walk":
				_teleport_walker(Vector2(2350, 600), PI * 0.3)
				cmd = PlayerCommand.make(Vector2(0.45, 1.0).normalized(), false, false, Vector2(2425, 694))
				await _frames(30)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2425, 694))
				await _frames(10)
				await _shot("walk")
			"drive":
				if main.player.on_foot():
					var c: Car = main.cars[0]
					main.walker.place(c.global_position + Vector2(0, -34), 0.0)
					await _frames(2)
					main.player.enter(c)
				# pull out of the parking space and cruise east down Marlowe Avenue
				cmd = PlayerCommand.make(Vector2(-0.45, -1.0))
				await _frames(26)
				cmd = PlayerCommand.make(Vector2(0.3, -1.0))
				await _frames(18)
				cmd = PlayerCommand.make(Vector2(0.0, -1.0))
				await _frames(40)
				await _shot("drive")
				cmd = PlayerCommand.make(Vector2(0, 0), true)
				await _frames(2)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(90)
			"steer":
				# M003: in the roadster at the curb, wheel turned to full lock (front tyres turn)
				var c: Car = main.cars[0]
				main.walker.place(c.global_position + Vector2(0, -34), 0.0)
				await _frames(2)
				main.player.enter(c)
				cmd = PlayerCommand.make(Vector2(-1.0, 0.0))
				await _frames(40)
				await _shot("steer")
				cmd = PlayerCommand.make(Vector2(-1.0, -1.0))
				await _frames(50)
				cmd = PlayerCommand.make(Vector2(-1.0, -0.0))
				await _frames(4)
				await _shot("steer_turning")
				cmd = PlayerCommand.make(Vector2(0, 1))
				await _frames(60)
				cmd = PlayerCommand.make(Vector2(0, 0), true)
				await _frames(2)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(60)
			"club":
				# M003: walk in under the Copper Owl's canopy; the roof opens up
				_teleport_walker(Vector2(2291, 480), -PI / 2)
				cmd = PlayerCommand.make(Vector2(0, -1), false, false, Vector2(2291, 300))
				await _frames(50)
				cmd = PlayerCommand.make(Vector2(-0.4, -1).normalized(), false, false, Vector2(2240, 202))
				await _frames(45)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2240, 202))
				await _frames(30)
				await _shot("club")
			"barber":
				# M003: Sal's Barber Shop, talking to Sal
				_teleport_walker(Vector2(990, 368), -PI / 2)
				await _frames(40)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(990, 334))
				main.start_talk("sal")
				await _frames(20)
				await _shot("barber")
				main.end_talk()
			"augie":
				_teleport_walker(Vector2(2240, 256), -PI / 2)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2240, 202))
				await _frames(40)
				main.rackets.bottles = 6
				main.hud.set_purse(main.rackets.money, main.rackets.bottles)
				main.start_talk("augie")
				await _frames(10)
				await _shot("augie")
				main.end_talk()
				main.rackets.bottles = 0
				main.hud.set_purse(main.rackets.money, main.rackets.bottles)
			"rourke":
				# M005: Rourke at his corner table, Danny holding his money from Augie and Novak
				_teleport_walker(Vector2(2302, 384), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2356, 400))
				await _frames(40)
				main.rackets.collect("copper_owl", false)
				main.rackets.collect("grocery", false)
				main.hud.set_purse(main.rackets.money, main.rackets.bottles, main.rackets.held)
				main.start_talk("rourke")
				await _frames(10)
				main._answer(0)  # "the envelope"
				await _frames(10)
				await _shot("rourke")
				main.end_talk()
			"bird":
				# M006: the Bird singing on the bandstand, Danny at a table
				_teleport_walker(Vector2(2300, 340), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2384, 333))
				await _frames(90)
				await _shot("bird")
			"bird_talk":
				# M006: the record scratched, the Bird giving Danny a piece of her mind
				_teleport_walker(Vector2(2343, 336), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2384, 333))
				await _frames(20)
				main.talk_to_bird()
				await _frames(30)
				await _shot("bird_talk")
				main.end_talk()
			"lefty":
				# M006: Lefty Moran outside Doyle's Garage, Danny walking up
				_teleport_walker(main.rival.body.global_position + Vector2(-80, 0), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, main.rival.body.global_position)
				await _frames(60)
				await _shot("lefty")
			"gunfight":
				# M006: Lefty hostile and shooting; then shot down
				_teleport_walker(main.rival.body.global_position + Vector2(-170, 0), 0.0)
				main.rival.provoke()
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, main.rival.body.global_position)
				_click = true
				await _frames(150)
				await _shot("gunfight")
				for i in 6:
					if main.rival.is_down():
						break
					main.rival.body.hit_by_bullet(main.rival.body.global_position, Vector2.RIGHT, main.walker)
				await _frames(20)
				await _shot("lefty_down")
			"ward_map", "city_map":
				# M006: the map of the whole ward (M)
				_teleport_walker(Vector2(2350, 600), PI * 0.3)
				await _frames(10)
				main.show_map(true)
				await _frames(5)
				await _shot(s, false)
				main.show_map(false)
			"vet":
				# M006: Doc Pettibone's surgery, Danny wounded and asking to be patched up
				main.walker.condition.shoot("left_arm", 0.5)
				main.rackets.money = 2000
				_teleport_walker(Vector2(2150, 1300), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2200, 1262))
				await _frames(40)
				main.start_talk("pettibone")
				await _frames(10)
				await _shot("vet")
				main.end_talk()
				main.walker.condition.heal_all()
			"status":
				# M006: how Danny is (C), after a bad night
				main.walker.condition.shoot("left_arm", 0.5)
				main.walker.condition.hurt("right_leg", 80)
				main.walker.condition.hurt("torso", 20)
				main.show_status(true)
				await _frames(5)
				await _shot("status", false)
				main.show_status(false)
				main.walker.condition.heal_all()
			"morgue":
				# M006: the Morgue on Pruitt Street
				_teleport_walker(Vector2(2820, 1470), -PI / 2)
				await _frames(40)
				await _shot("morgue")
			"fight":
				# M007: a fistfight with Lefty Moran outside Doyle's Garage, the dial over the street
				_teleport_walker(main.rival.body.global_position + Vector2(-42, 0), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, main.rival.body.global_position)
				await _frames(20)
				main.start_fight(main.rival.body, "Lefty Moran", func(_w, _r): pass)
				var dial: FightDial = main.hud.fight_dial
				# land the first punch, then catch the second check mid-sweep
				while dial.fight.phase != FistFight.Phase.RUNNING:
					await process_frame
				while not dial.fight.in_zone():
					await process_frame
				dial.press()
				await _frames(4)
				await _shot("fight_landed", false)
				while dial.fight.phase != FistFight.Phase.RUNNING:
					await process_frame
				while dial.fight.needle < dial.fight.zone_start * 0.7:
					await process_frame
				await _shot("fight", false)
				while main.fighting:
					await process_frame
			"job_offer":
				# M007: Rourke offers the job at his corner table (the line's performance tag beside his name)
				await _at_spot("copper_owl", "rourke")
				main.voice_lines.mark("rourke_greeting")  # met him already: straight to business
				main.start_talk("rourke")
				main._answer(_option("job_offer"))
				await _frames(10)
				await _shot("job_offer")
				main.end_talk()
			"lindqvist_tells":
				# M007: the Swede names the man
				main.rackets.job.stage = RourkeJob.Stage.ACCEPTED
				await _at_spot("hardware", "lindqvist")
				main.start_talk("lindqvist")
				main._answer(_option("job_ask"))
				await _frames(10)
				await _shot("lindqvist_tells")
				main.end_talk()
			"job_map":
				# M007: the job on the ward map - a few words under the key, a ring round Lefty's corner
				main.rackets.job.stage = RourkeJob.Stage.ACCEPTED
				main.rackets.job.learn("culprit")
				_teleport_walker(Vector2(2280, 1050), PI * 0.5)
				await _frames(10)
				main.show_map(true)
				await _frames(5)
				await _shot("job_map", false)
				main.show_map(false)
			"confront":
				# M007: outside Doyle's Garage - talk, threaten or fight
				main.rackets.job.stage = RourkeJob.Stage.ACCEPTED
				main.rackets.job.learn("culprit")
				var lefty_at: Vector2 = main.rival.body.global_position
				_teleport_walker(lefty_at + Vector2(-34, 6), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, lefty_at)
				await _frames(25)
				main.talking = "lefty"
				main._show(main.talk.open("lefty", main._talk_context()))
				await _frames(10)
				await _shot("confront")
				main.end_talk()
			"report":
				# M007: telling Rourke how it went
				main.rackets.job.stage = RourkeJob.Stage.ACCEPTED
				main.rackets.job.learn("culprit")
				main.rackets.job.resolve("beaten", main.rackets)
				main.rackets.boss.purse = 3000
				await _at_spot("copper_owl", "rourke")
				main.start_talk("rourke")
				main._answer(_option("job_report"))
				main._answer(_option("job_truth_hand"))
				await _frames(10)
				await _shot("report")
				main.end_talk()
			"yards", "yards_dock", "yards_sidings", "border_south":
				# M008: the Riverfront Yards (streamed in as Danny comes near, here at once)
				main.world.load_now("yards")
				var at := {"yards": Vector2(1650, 3060), "yards_dock": Vector2(3640, 3150), "yards_sidings": Vector2(900, 4860),
					"border_south": Vector2(1650, 2640)}[s] as Vector2
				_teleport_walker(at, PI * 0.5)
				await _frames(40)
				await _shot(s)
			"square", "bijou", "church", "border_west":
				# M008: Halloran Square (streamed in as Danny comes near, here at once)
				main.world.load_now("halloran")
				var at2 := {"square": Vector2(-3075, 1000), "bijou": Vector2(-2120, 620), "church": Vector2(-3500, 900),
					"border_west": Vector2(-1650, 640)}[s] as Vector2
				_teleport_walker(at2, PI)
				await _frames(40)
				await _shot(s)
			"city_map_wide", "city_map_square":
				# M008: the city map zoomed out over all three districts, and looking at Halloran Square
				_teleport_walker(Vector2(2350, 600), PI * 0.3)
				await _frames(10)
				main.show_map(true)
				var cm: CityMap = main.hud.city_map
				if s == "city_map_wide":
					cm.zoom_at(cm.map_rect.get_center(), 100.0)
				else:
					cm.centre = Vector2(-3000, 900)
					cm.zoom_at(cm.map_rect.get_center(), 0.8)
				await _frames(5)
				await _shot(s, false)
				main.show_map(false)
			"crossing":
				# M008: Danny's sedan crossing from the ward into the yards on Kessler Street, lights on
				main.world.load_now("yards")
				var sedan: Car = main.cars[7]
				sedan.place(Transform2D(PI / 2, Vector2(1690, 2660)))
				sedan.model.position = Vector2(1690, 2660)
				_teleport_walker(Vector2(1640, 2600), 0.0)
				await _frames(2)
				main.player.enter(sedan)
				main.camera.snap_to(sedan)
				await _frames(40)
				await _shot("crossing")
				main.player.exit_car()
			"police_shooting":
				# M008: the beat cop on Marlowe Avenue saw Danny shoot a man: he draws and fires
				var cop: PoliceOfficer = main.officer
				var victim := Walker.create(main.resolver, "characters/worker", {"glow": false})
				main.add_child(victim)
				victim.place(cop.body.global_position + Vector2(40, 140), 0.0)
				_teleport_walker(cop.body.global_position + Vector2(140, 250), -PI * 0.6)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, victim.global_position)
				await _frames(5)
				cop.brain.witness_violence(main.walker.global_position)
				var fired := [false]
				cop.fired.connect(func(_m: Vector2, _d: Vector2) -> void: fired[0] = true)
				for i in 400:
					if fired[0]:
						break
					await process_frame
				await _shot("police_shooting", false)
				victim.queue_free()
			"sound_levels":
				# M005: the pause screen with the six sound levels
				_teleport_walker(Vector2(2291, 520), -PI / 2)
				await _frames(20)
				var esc := InputEventAction.new()
				esc.action = CityInput.MENU
				esc.pressed = true
				main._unhandled_input(esc)
				var down := InputEventAction.new()
				down.action = "ui_down"
				down.pressed = true
				main._unhandled_input(down)
				await _frames(5)
				await _shot("sound_levels")
				main._unhandled_input(esc)
			"grocery":
				_teleport_walker(Vector2(1921, 838), 0.0)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(1976, 838))
				await _frames(40)
				main.start_talk("novak")
				main._answer(0)
				await _frames(10)
				await _shot("grocery")
				main.end_talk()
			"eddie":
				_teleport_walker(Vector2(1032, 952), PI)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(982, 955))
				await _frames(40)
				main.start_talk("eddie")
				await _frames(10)
				await _shot("eddie")
				main.end_talk()
			"opening":
				# M005: the opening narration over the ward, at moments through the monologue
				main.walker.place(main.layout.spawn, main.layout.spawn_facing)
				main._start_opening()
				var marks := [[1.2, "opening_fade"], [4.0, "opening_river"], [8.6, "opening_club"], [15.0, "opening_junction"],
					[20.5, "opening_street"], [22.6, "opening_home"]]
				for m in marks:
					while main.opening != null and main.opening.time < m[0]:
						await process_frame
					await _shot(m[1], false)
				while main.opening != null:
					await process_frame
				await _frames(30)
				await _shot("opening_handover")
			"home":
				# M003: where every night begins
				_teleport_walker(main.layout.spawn, PI * 0.5)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, main.layout.spawn + Vector2(0, 60))
				await _frames(40)
				await _shot("home")
			"wake":
				main.sleep()
				await _frames(135)
				await _shot("wake")
			"traffic":
				# M003: Marlowe Avenue with the evening's cars and passers-by
				_teleport_walker(Vector2(2250, 600), 0.0)
				await _frames(150)
				await _shot("traffic")
			"squad_car":
				_teleport_walker(Vector2(1900, 1065), PI)
				await _frames(40)
				await _shot("squad_car")
			"cars":
				# M004: the cars parked every which way, lights off: which end is the front?
				var spots := [[Vector2(2240, 1470), 0.0], [Vector2(2360, 1470), PI], [Vector2(2470, 1500), -PI / 2],
					[Vector2(2560, 1500), PI / 2], [Vector2(2680, 1490), 0.7], [Vector2(2800, 1490), PI + 0.5]]
				var picks := ["sedan", "coupe", "police", "sedan", "coupe", "sedan"]
				var used := []
				for k in spots.size():
					for c in main.cars:
						if c.vehicle.id == picks[k] and not used.has(c):
							used.append(c)
							c.place(Transform2D(spots[k][1], spots[k][0]))
							break
				main.street.clear()
				_teleport_walker(Vector2(2520, 1430), PI / 2)
				await _frames(40)
				await _shot("cars")
			"wheels", "wheels_lock":
				# M009: the front tyres tucked under the wings, close up, in four headings;
				# wheels_lock: the same cars with the wheels at full lock
				var wspots := [[Vector2(2260, 1480), 0.0], [Vector2(2380, 1480), PI / 2], [Vector2(2500, 1480), PI],
					[Vector2(2620, 1480), -PI / 4]]
				var wpicks := ["sedan", "coupe", "police", "sedan"]
				var wused := []
				for k in wspots.size():
					for c in main.cars:
						if c.vehicle.id == wpicks[k] and not wused.has(c) and not c.has_meta("away"):
							wused.append(c)
							c.place(Transform2D(wspots[k][1], wspots[k][0]))
							c.model.position = wspots[k][0]
							break
				main.street.clear()
				main.walker.place(Vector2(2440, 1700), PI / 2)  # out of the picture
				var mid := Node2D.new()
				main.add_child(mid)
				mid.global_position = Vector2(2440, 1480)
				main.camera.zoom_override = 2.4
				main.camera.snap_to(mid)
				for f in 40:
					for c in wused:
						(c as Car).model.steer_level = 1.0 if s == "wheels_lock" else 0.0
					await _frames(1)
				await _shot(s, false)
				main.camera.zoom_override = 0.0
				main.camera.snap_to(main.walker)
				mid.queue_free()
			"weather_clear", "weather_rain", "weather_fog", "weather_rain_fog", "fog_alley", "fog_headlights":
				# M010: the four kinds of night on Marlowe Avenue by the Copper Owl; the fog in a back alley;
				# a car's headlights in the fog
				main.weather.force({"weather_clear": "clear", "weather_rain": "rain", "weather_fog": "fog",
					"weather_rain_fog": "rain_fog", "fog_alley": "fog", "fog_headlights": "rain_fog"}[s])
				if s == "fog_alley":
					_teleport_walker(Vector2(1800, 135), 0.0)
				elif s == "fog_headlights":
					var fc: Car = main.cars[0]
					fc.place(Transform2D(PI, Vector2(2420, 640)))
					main.walker.place(fc.global_position + Vector2(0, -34), 0.0)
					await _frames(2)
					main.player.enter(fc)
					cmd = PlayerCommand.make(Vector2(0, -1))
					await _frames(50)
					cmd = PlayerCommand.make(Vector2(0, 0.4))
					await _frames(10)
				else:
					_teleport_walker(Vector2(2250, 560), -PI / 2)
				await _frames(40)
				await _shot(s, false)
				cmd = PlayerCommand.new()
			"drowsy":
				# M010: half past five in the morning, on Marlowe Avenue: heavy eyes
				main.weather.force("clear")
				_teleport_walker(Vector2(2250, 560), -PI / 2)
				main.clock.set_time(float(main.night_rules.dawn_minute) - 5.0)
				await _frames(200)
				await _shot("drowsy", false)
			"map_labels", "map_medium":
				# M010: the city map close up over the Copper Owl's block (every building named or addressed),
				# and at medium zoom (the businesses and streets)
				main.weather.force("clear")
				_teleport_walker(Vector2(2300, 600), 0.0)
				await _frames(5)
				var mk := InputEventAction.new()
				mk.action = CityInput.MAP
				mk.pressed = true
				main._unhandled_input(mk)
				var cm: CityMap = main.hud.city_map
				cm.scale_px = 2.4 if s == "map_labels" else 7.0
				cm.centre = Vector2(2150, 520)
				cm._clamp_centre()
				cm.queue_redraw()
				await _frames(5)
				await _shot(s, false)
				main._unhandled_input(mk)
			"ping":
				# M010: an argument getting heated outside the Copper Owl, heard from down the street: a ring on the minimap
				main.weather.force("clear")
				_teleport_walker(Vector2(1000, 1500), 0.0)
				main.incidents.plan = [{"id": "shot_p", "kind": "argument", "spot": "owl_kerb", "at": main.clock.minute + 0.5, "tries": 0}]
				main.clock.set_time(main.clock.minute + 1.0)
				main._advance_incidents()
				main.clock.set_time(main.clock.minute + 13.0)
				main._advance_incidents()
				_teleport_walker(Vector2(1760, 900), -0.9)
				await _frames(40)
				_teleport_walker(Vector2(1700, 980), -0.9)
				await _frames(14)
				await _shot("ping", false)
			"truck_found":
				# M010: Brennan's coal truck at the kerb of Wharf Street, as a driver coming down from the ward sees it
				var tl: DistrictLayout = main.world.layouts.yards
				var tspec: Dictionary = tl.cars.filter(func(x: Dictionary) -> bool: return x.type == "dump_truck")[0]
				_teleport_walker(tspec.pos + Vector2(-110, -260), PI / 2)
				main.world.load_now("yards")
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, tspec.pos)
				await _frames(40)
				await _shot("truck_found", false)
				cmd = PlayerCommand.new()
			"back_room", "poker_game":
				# M010: the Copper Owl's back room - the regulars at the green-shaded lamp; poker_game:
				# Danny sat in, a few hands on, his turn on the flop or later
				main.weather.force("clear")
				var bplan: InteriorPlan = main.interiors.view_of("back_room").plan
				_teleport_walker(bplan.spots[0].pos + Vector2(30, 0), -PI / 2 - 0.5)
				await _frames(30)
				if s == "poker_game":
					main.rackets.money = 1500
					_teleport_walker(bplan.spots[0].pos, -PI / 2)
					await _frames(3)
					main._interact(main.walker.global_position)
					await _frames(5)
					var pv: PokerView = main.hud.poker_view
					pv.choose_buy_in(1)
					pv.think = Vector2(0.05, 0.1)
					pv.between_hands = 0.3
					var dealt := 0
					for f in 4000:
						var tb: Holdem = main.poker.table
						if tb == null:
							break
						if tb.running() and tb.to_act == main.poker.danny:
							if main.poker.hands >= 3 and tb.street >= Holdem.FLOP:
								break
							pv.act(2 if tb.legal(main.poker.danny).check else (2 if tb.legal(main.poker.danny).call <= 20 else 1))
						await _frames(1)
					pv.think = Vector2(0.7, 1.4)
					await _frames(10)
				await _shot(s, false)
				if s == "poker_game":
					main.leave_poker()
			"thompson":
				# M010: Eddie's Thompson, borrowed, in a burst down the alley behind the Copper Owl
				main.weather.force("clear")
				main.street.clear()
				main.rackets.money = 2000
				main.rackets.borrow_thompson()
				main._arm_thompson(true)
				_teleport_walker(Vector2(2330, 135), PI)
				main.player.switch_gun()
				await _frames(4)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2000, 150))
				cmd.fire = true
				_click = true
				await _frames(50)
				for f in 8:  # the moment a round goes: the muzzle flash
					if main.gunfire._flash.visible:
						break
					await _frames(1)
				await _shot("thompson", false)
				cmd = PlayerCommand.new()
			"cafe_packard", "cafe_blast", "cafe_aftermath":
				# M010: Rosie's Café on Marlowe Avenue, Halloran Square - Duggan's Packard at the kerb at
				# half past ten; the blast in the short film (the flash and the fireball under the bars);
				# a little later: the wreck burning, the smoke, the scorch, the café's people on the pavement
				main.weather.force("clear")
				main.street.clear()
				var hl2: DistrictLayout = main.world.layouts.halloran
				var car_at: Vector2 = hl2.cafe_point("car").pos
				var bench_at: Vector2 = hl2.cafe_point("bench").pos
				_teleport_walker(car_at + Vector2(140, 120), -PI / 2 - 0.3)
				main.world.load_now("halloran")
				main.clock.set_time(22 * 60.0 + 30.0)
				await _frames(20)
				if s != "cafe_packard":
					main.rackets.money = 2000
					main.rackets.take_cafe_job()
					main.rackets.buy_parcel()
					main.rackets.plant_parcel(main.clock.minute, false)
					_teleport_walker(bench_at + Vector2(0, 28), PI)
					await _frames(10)
					main.clock.set_time(main.rackets.cafe.due(main.rackets.night) - 0.02)
					for f in 60:
						await _frames(1)
						if main.cafe_film != null:
							break
					if s == "cafe_blast":
						for f in 400:
							await _frames(1)
							if main.cafe_film != null and main.cafe_film.time >= 4.3:
								break
					else:
						for f in 60 * 9:
							await _frames(1)
							if main.cafe_film == null:
								break
						if main.cafe_film != null:
							main.cafe_film.skip()
						await _frames(120)
						_teleport_walker(car_at + Vector2(150, 150), -PI / 2 - 0.6)
						await _frames(60)
				await _shot(s, false)
			"emergency":
				# M010: after the blast at Rosie's: the police car, the fire engine and the ambulance at the
				# kerb with their lamps going, the coppers keeping people back, the firemen at the wreck
				main.weather.force("clear")
				main.street.clear()
				var hl3: DistrictLayout = main.world.layouts.halloran
				var car3: Vector2 = hl3.cafe_point("car").pos
				_teleport_walker(hl3.cafe_point("bench").pos + Vector2(0, 28), PI)
				main.world.load_now("halloran")
				main.clock.set_time(22 * 60.0 + 30.0)
				await _frames(10)
				main.rackets.money = 2000
				main.rackets.take_cafe_job()
				main.rackets.buy_parcel()
				main.rackets.plant_parcel(main.clock.minute, false)
				main.clock.set_time(main.rackets.cafe.due(main.rackets.night) - 0.02)
				for f in 60:
					await _frames(1)
					if main.cafe_film != null:
						break
				if main.cafe_film != null:
					main.cafe_film.skip()
				for f in 60 * 30:
					await _frames(1)
					if main.emergency.units.all(func(u: Dictionary) -> bool: return u.state == "stopped"):
						break
				await _frames(480)  # the crews walk over to their places
				_teleport_walker(car3 + Vector2(260, 170), -PI / 2 - 0.4)
				await _frames(30)
				await _shot("emergency", false)
			"park", "sitting":
				# M010: Halloran Park in the middle of the square - lawns, paths, railings, benches;
				# sitting: Danny on a bench by the north path, the night going by
				main.weather.force("clear")
				var hl: DistrictLayout = main.world.layouts.halloran
				var pm: Vector2 = hl.landmarks.filter(func(l: Dictionary) -> bool: return l.label == "Halloran Park")[0].pos
				_teleport_walker(pm + Vector2(-60, -230), PI / 2)
				main.world.load_now("halloran")
				await _frames(20)
				if s == "sitting":
					var near: Array = main._seats_near().filter(func(x: Dictionary) -> bool: return (x.pos as Vector2).distance_to(pm) < 200.0)
					near.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a.pos as Vector2).y < (b.pos as Vector2).y)
					_teleport_walker(near[0].stand, 0.0)
					await _frames(2)
					main._interact(main.walker.global_position)
					cmd = PlayerCommand.make(Vector2.ZERO, false, true)
					await _frames(40)
				await _frames(20)
				await _shot(s, false)
				cmd = PlayerCommand.new()
			"dump_truck", "school_bus":
				# M009: Brennan's coal truck pulling out of its dock onto Front Street; the
				# parish school bus pulling away from the kerb beside St. Brendan's
				var did: String = "yards" if s == "dump_truck" else "halloran"
				var vl: DistrictLayout = main.world.layouts[did]
				var vspec: Dictionary = vl.cars.filter(func(x: Dictionary) -> bool: return x.type == s)[0]
				_teleport_walker(vspec.pos + Vector2(-40, 0), 0.0)
				main.world.load_now(did)
				await _frames(20)
				var hv: Car = main.cars.filter(func(x: Car) -> bool: return x.vehicle.id == s)[0]
				main.walker.place(hv.global_position + Vector2(-34, 20), 0.0)
				await _frames(2)
				main.player.enter(hv)
				cmd = PlayerCommand.make(Vector2(0.0, -1.0))
				await _frames(100 if s == "dump_truck" else 120)
				cmd = PlayerCommand.make(Vector2(-0.6 if s == "dump_truck" else -0.35, -1.0))
				await _frames(50)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(10)
				await _shot(s, false)
				cmd = PlayerCommand.make(Vector2(0, 1))
				await _frames(60)
				cmd = PlayerCommand.new()
			"incident", "incident_broken_up":
				# M009: an argument outside the Copper Owl, getting heated, with nobody's help;
				# incident_broken_up: Danny steps in and they part, still muttering
				main.street.clear()
				_teleport_walker(Vector2(1000, 1500), 0.0)
				main.incidents.plan = [{"id": "shot_a", "kind": "argument", "spot": "owl_kerb", "at": main.clock.minute + 0.5, "tries": 0}]
				main.clock.set_time(main.clock.minute + 1.0)
				main._advance_incidents()
				main.clock.set_time(main.clock.minute + 13.0)  # into the heated part
				main._advance_incidents()
				_teleport_walker(Vector2(2190, 560), PI + 0.6)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2120, 462))
				await _frames(150)
				if s == "incident_broken_up":
					main._incident_talking = "shot_a"
					main._step_in("calm")
					await _frames(70)
				await _shot(s, false)
				cmd = PlayerCommand.new()
			"incident_stop":
				# M009: the ward's beat cop has stopped a man on Marlowe Avenue and questions him
				main.street.clear()
				_teleport_walker(Vector2(1000, 1500), 0.0)
				main.incidents.plan = [{"id": "shot_s", "kind": "stop", "spot": "marlowe_stop", "at": main.clock.minute + 0.5, "tries": 0}]
				main.clock.set_time(main.clock.minute + 1.0)
				main._advance_incidents()
				_teleport_walker(Vector2(2010, 590), -0.4)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, Vector2(2070, 462))
				await _frames(60 * 9)
				await _shot("incident_stop", false)
				cmd = PlayerCommand.new()
			"dutch", "crate":
				# M009: Dutch outside his night lunch, his crate by the door, the sedan at the kerb;
				# crate: loaded, strapped on behind the sedan as Danny drives off
				var yl: DistrictLayout = main.world.layouts.yards
				var cp: Vector2 = yl.errands[0].pos
				_teleport_walker(yl.contacts[0].pos + Vector2(0, 30), -PI / 2)
				main.world.load_now("yards")
				var ys: Car = main.my_car()
				ys.place(Transform2D(PI, cp + Vector2(10, 74)))
				await _frames(20)
				if s == "dutch":
					main.walker.place(yl.contacts[0].pos + Vector2(4, 30), -PI / 2)
					await _frames(10)
					await _frames(10)
					main._interact(main.walker.global_position)
					await _frames(30)
					await _shot("dutch", false)
					main.end_talk()
				else:
					main.rackets.opportunities.take_crate()
					main.walker.place(cp + Vector2(0, 20), -PI / 2)
					await _frames(5)
					main._take_errand("crate", cp)
					main.walker.place(ys.global_position + Vector2(0, -34), 0.0)
					await _frames(2)
					main.player.enter(ys)
					cmd = PlayerCommand.make(Vector2(0.0, -1.0))
					await _frames(70)
					cmd = PlayerCommand.new()
					await _shot("crate", false)
			"feeney", "film_can":
				# M009: Mr. Feeney under the Bijou's marquee asks for help; film_can: the lost
				# reel in St. Brendan's churchyard
				var hl: DistrictLayout = main.world.layouts.halloran
				if s == "feeney":
					_teleport_walker(hl.contacts[0].pos + Vector2(-4, 30), -PI / 2)
					main.world.load_now("halloran")
					await _frames(20)
					await _frames(10)
					main._interact(main.walker.global_position)
					await _frames(30)
					await _shot("feeney", false)
					main.end_talk()
				else:
					var fc: Vector2 = hl.errands[0].pos
					_teleport_walker(fc + Vector2(-40, 50), -0.9)
					main.world.load_now("halloran")
					cmd = PlayerCommand.make(Vector2.ZERO, false, false, fc)
					await _frames(40)
					await _shot("film_can", false)
					cmd = PlayerCommand.new()
			"grocery_door":
				_teleport_walker(Vector2(1900, 520), PI / 2)
				await _frames(40)
				await _shot("grocery_door")
			"grocery_marker":
				# M004: at Novak's door: its marker pulses, E enters
				var gp: InteriorPlan = main.interiors.view_of("grocery").plan
				_teleport_walker(gp.outside_door(0, 16.0), PI / 2)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, gp.door_centre(0))
				await _frames(40)
				await _shot("grocery_marker")
			"drive_markers":
				# M004: driving west down Marlowe Avenue: Sal's and Lindqvist's markers come up
				var dc: Car = main.cars[1]
				dc.place(Transform2D(PI, Vector2(1700, 555)))
				main.walker.place(dc.global_position + Vector2(0, -34), 0.0)
				await _frames(2)
				main.player.enter(dc)
				cmd = PlayerCommand.make(Vector2(0.0, -1.0))
				await _frames(150)
				await _shot("drive_markers")
				cmd = PlayerCommand.make(Vector2(0, 0), true)
				await _frames(2)
				cmd = PlayerCommand.make(Vector2(0, 0))
				await _frames(90)
			"club_door":
				_teleport_walker(Vector2(2291, 455), -PI / 2)
				await _frames(40)
				await _shot("club_door")
			"garage":
				_teleport_walker(Vector2(1180, 1395), -PI / 2)
				await _frames(40)
				await _shot("garage")
			"river":
				_teleport_walker(Vector2(3560, 470), 0.0)
				await _frames(40)
				await _shot("river")
			"alley":
				_teleport_walker(Vector2(2300, 135), PI)
				await _frames(40)
				await _shot("alley")
			"hotel":
				_teleport_walker(Vector2(2480, 735), -PI / 2)
				await _frames(40)
				await _shot("hotel")
			"shoot":
				# a few steps up the avenue, then two shots at the Copper Owl's windows
				var target := Vector2(2240, 380)
				cmd = PlayerCommand.make(Vector2(-0.3, -0.5), false, false, target)
				await _frames(24)
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, target)
				_click = true
				await _frames(26)
				_click = true
				_flash_seen = false
				main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
				for i in 30:
					await physics_frame
					if _flash_seen:
						break
				await process_frame
				await _shot("shoot", false)
				# the same moment, close up: the pistol in his hand
				main.camera.foot_zoom = 2.6
				for i in 70:
					await process_frame
				_click = true
				_flash_seen = false
				main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
				for i in 30:
					await physics_frame
					if _flash_seen:
						break
				await process_frame
				await _shot("shoot_close", false)
				main.camera.foot_zoom = 1.2
				await _frames(60)
			"beat":
				# the officer on his beat, seen from the corner of Kessler and Marlowe
				_teleport_walker(Vector2(1990, 560), -PI / 2)
				await _frames(150)
				await _shot("beat")
			"pursuit":
				# shots by the newsstand: the officer whistles and comes running
				_teleport_walker(Vector2(2330, 600), PI)
				await _frames(10)
				var near: Vector2 = main.officer.body.global_position
				cmd = PlayerCommand.make(Vector2.ZERO, false, false, near + Vector2(80, -60))
				_click = true
				await _frames(30)
				_click = true
				await _frames(50)
				# run for the roadster
				var car: Car = main.cars[0]
				for i in 120:
					var to: Vector2 = car.global_position + Vector2(0, -36) - main.walker.global_position
					if to.length() < 8.0:
						break
					cmd = PlayerCommand.make(to.normalized(), false, false, main.officer.body.global_position)
					await physics_frame
				await _shot("pursuit")
				main.player.enter(car)
				cmd = PlayerCommand.make(Vector2(-0.4, -1))
				await _frames(30)
				cmd = PlayerCommand.make(Vector2(0, -1))
				await _frames(50)
				await _shot("escape")
			"story":
				await _story()
			"wide":
				_teleport_walker(Vector2(1650, 600), 0.0)
				main.camera.foot_zoom = 0.45
				await _frames(120)
				await _shot("wide")
				main.camera.foot_zoom = 1.4
	quit()


## M007: stands Danny at someone's talk spot in a room.
func _at_spot(plan_id: String, person: String) -> void:
	for sp in main.interiors.view_of(plan_id).plan.spots:
		if sp.id == person:
			_teleport_walker(sp.pos, -PI / 2)
	await _frames(40)


## The index of the answer `id` on the page on screen (-1: none).
func _option(id: String) -> int:
	var opts: Array = main._page.get("options", [])
	for i in opts.size():
		if opts[i].id == id:
			return i
	return -1


func _drive(c: Car, points: Array, cruise: float, max_ticks: int) -> void:
	var i := 0
	for t in max_ticks:
		var target: Vector2 = points[i]
		if c.global_position.distance_to(target) < 45.0:
			i += 1
			if i >= points.size():
				break
			target = points[i]
		var diff := angle_difference(c.model.heading, (target - c.global_position).angle())
		var steer := 0.0
		if diff > 0.05:
			steer = 1.0
		elif diff < -0.05:
			steer = -1.0
		var speed := c.model.forward_speed()
		var want := cruise if absf(diff) < 0.45 else cruise * 0.45
		var pedal := -1.0 if speed < want else (1.0 if speed > want + 50.0 else 0.0)
		cmd = PlayerCommand.make(Vector2(steer, pedal))
		await physics_frame
	cmd = PlayerCommand.new()


## The M002 sequence, as described for the milestone.
func _story() -> void:
	var cop: PoliceOfficer = main.officer
	await _frames(90)
	await _shot("story_1_officer_on_his_beat")
	# a few shots at the Copper Owl's windows
	var target := Vector2(2250, 380)
	cmd = PlayerCommand.make(Vector2.ZERO, false, false, target)
	_click = true
	await _frames(26)
	_click = true
	_flash_seen = false
	main.player.fired.connect(func(_m: Vector2, _d: Vector2) -> void: _flash_seen = true, CONNECT_ONE_SHOT)
	for i in 30:
		await physics_frame
		if _flash_seen:
			break
	await process_frame
	await _shot("story_2_shots_fired", false)
	await _frames(40)
	# run for the roadster, the copper coming
	var car: Car = main.cars[0]
	for i in 200:
		var to: Vector2 = car.global_position + Vector2(0, -36) - main.walker.global_position
		if to.length() < 6.0:
			break
		cmd = PlayerCommand.make(to.normalized(), false, false, cop.body.global_position)
		await physics_frame
		if i == 25:
			await _shot("story_3_on_your_tail", false)
	main.player.enter(car)
	await _drive(car, [Vector2(2700, 650), Vector2(2950, 650)], 260.0, 90)
	await _shot("story_4_getaway_down_marlowe")
	# north up Wharf Street and into the back alley
	await _drive(car, [Vector2(3150, 640), Vector2(3290, 560), Vector2(3300, 300), Vector2(3270, 175), Vector2(3150, 140)], 230.0, 600)
	await _drive(car, [Vector2(2900, 138)], 140.0, 160)
	await _shot("story_5_into_the_alley")
	# meanwhile, back on Marlowe Avenue: the copper looking for you
	for i in 600:
		if cop.brain.state == OfficerBrain.State.SEARCH:
			break
		await physics_frame
	main.camera.target = cop.body
	await _frames(70)
	await _shot("story_6_copper_searching")
	main.camera.target = car
	for i in 1200:
		if cop.brain.state == OfficerBrain.State.RETURN:
			break
		await physics_frame
	await _frames(20)
	await _shot("story_7_you_lost_him")
