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
## Moran outside Doyle's Garage; shooting, then shot down: lefty_down), ward_map, vet, status, morgue (M006), fight / fight_landed (M007).

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
			"ward_map":
				# M006: the map of the whole ward (M)
				_teleport_walker(Vector2(2350, 600), PI * 0.3)
				await _frames(10)
				main.show_map(true)
				await _frames(5)
				await _shot("ward_map", false)
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
				var at := {"yards": Vector2(1650, 3060), "yards_dock": Vector2(3640, 3150), "yards_sidings": Vector2(3300, 4720),
					"border_south": Vector2(1650, 2640)}[s] as Vector2
				_teleport_walker(at, PI * 0.5)
				await _frames(40)
				await _shot(s)
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
