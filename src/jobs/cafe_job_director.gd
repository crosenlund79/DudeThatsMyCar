class_name CafeJobDirector
extends JobDirector
## M014 (from main): the game side of Rourke's job at Rosie's Cafe (M010) -
## Vince Duggan's Packard at the kerb, the parcel slipped under it (a copper
## who could see Danny there is the only credible reason to suspect him), the
## quarter hour, the short film if Danny is near enough to watch, the blast,
## the coppers and the street, the police car, the fire engine and the
## ambulance, the wreck. The job's course and the pay are the pure CafeJob
## (in Rackets); the scene's nodes are CafeScene and EmergencyViews.

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


var scene: CafeScene
## M010: the police car, the fire engine and the ambulance that come to it.
var emergency := EmergencyResponse.new()
var emergency_views: EmergencyViews


func id() -> String:
	return "cafe"


## The cafe's scene and the emergency's vehicles, made where main made them (M010).
func build() -> void:
	scene = CafeScene.new()
	game.root.add_child(scene)
	scene.setup(game.world.layouts.halloran, game.resolver, game.rackets.cafe)
	emergency_views = EmergencyViews.new()
	game.root.add_child(emergency_views)
	emergency_views.setup(game.resolver, emergency)
	emergency_views.fire_out.connect(scene.extinguish)


func effects() -> Dictionary:
	return {
		"parcel": func(_v: Variant, _e: Dictionary) -> void: game.show_purse(),
		"cafe": func(v: Variant, _e: Dictionary) -> void:
			if String(v) == "reported":
				game.show_purse(),
	}


## Duggan's Packard, with the parcel in Danny's coat.
func spot(at: Vector2) -> Dictionary:
	var r := game.rackets
	if scene != null and r.parcels > 0 and r.cafe.stage == CafeJob.Stage.ACCEPTED and scene.near_car(at):
		return {"id": "plant", "prompt": "Slip the parcel under the Packard"}
	return {}


func use(_spot: Dictionary) -> void:
	plant_parcel()


## The parcel goes under Duggan's Packard. A copper who could see the car from
## where he stands saw Danny at it (a credible reason to suspect him later);
## otherwise nobody knows who did it. The quarter hour starts.
func plant_parcel() -> void:
	var r := game.rackets
	var at := scene.car_pos
	var witnessed := game.police.saw_danny_at(at)
	if not r.plant_parcel(game.clock.minute, witnessed):
		return
	game.night.moments.append(r.cafe.due(r.night))  # sitting and letting the time pass slows for it
	game.show_purse()
	game.hud.show_notice("You stoop by the running board as if to tie a shoelace, and stand up without the parcel. "
		+ "A quarter of an hour, Eddie said. Somewhere to watch from - not too close.")
	game.save()


## The clock: the Packard at the kerb (or not), the fuse when it is due, the
## emergency on its way.
func clock(minute: float, delta: float) -> void:
	if scene == null:
		return
	var r := game.rackets
	scene.job = r.cafe
	if minute >= r.cafe.due(r.night) and game.films.of("cafe") == null:
		_due()
	scene.refresh(r.night, minute)
	emergency_views.update(r.night, minute, delta)


## The quarter hour is up. Danny near enough to see it (and free to): the short
## film; otherwise it simply goes off, and he hears it if he is close.
func _due() -> void:
	var r := game.rackets
	var player := game.player
	var at := scene.car_pos
	var me := player.body().global_position
	if not r.cafe_blasted(game.clock.minute):
		return
	game.night.moments.erase(r.cafe.blast_minute)
	var watching := me.distance_to(at) <= CafeJob.WATCH and game.films.of("opening") == null and not game.fights.fighting \
		and not game.hud.poker_view.is_open() and (game.interiors.current == null or not player.on_foot())
	if watching:
		_start_film(at)
	else:
		_goes_off()
		if me.distance_to(at) <= 2600.0:
			game.hud.show_notice("A heavy boom rolls over the rooftops from somewhere toward Halloran Square.")


## The short film (in the game itself, like the opening): bars in, the camera
## leaves Danny for the cafe across the avenue, a hush, the flash, the street
## shaking, the people spilling out, and back to Danny as a siren starts up.
func _start_film(at: Vector2) -> void:
	game.dialogue.end()
	var player := game.player
	var camera := game.camera
	player.passing_time = false  # the night goes at its own pace while it plays
	var me := player.body().global_position
	var z := camera.zoom.x
	var keys := [
		{"t": 0.0, "pos": me, "zoom": z},
		{"t": 2.6, "pos": at.lerp(me, 0.25), "zoom": z * 1.25},
		{"t": 4.2, "pos": at, "zoom": z * 1.4},
		{"t": 6.0, "pos": at + Vector2(0, -20), "zoom": z * 1.2},
		{"t": 9.5, "pos": at.lerp(me, 0.2), "zoom": z * 1.1},
		{"t": 12.0, "pos": me, "zoom": z},
	]
	var captions := [
		{"t": 0.3, "text": "Through Rosie's window Vince Duggan is on his second cup, his back to the street."},
		{"t": 2.8, "text": "Marlowe Avenue goes quiet. Somewhere a streetcar bell. A dog."},
		{"t": 4.0, "text": ""},
		{"t": 5.2, "text": "Every window on the block comes in at once."},
		{"t": 7.6, "text": "Duggan comes out with his napkin still tucked in his collar. He doesn't say a word."},
		{"t": 10.2, "text": "Over toward Halloran Avenue, a siren starts up."},
	]
	var cues := [{"t": 3.4, "id": "hush"}, {"t": 4.0, "id": "blast"}, {"t": 10.0, "id": "siren"}]
	var film := Cinematic.new()
	game.root.add_child(film)
	film.start(keys, captions, cues, load(Hud.FONT_PATH))
	film.cue.connect(_on_cue)
	film.finished.connect(_end_film)
	game.films.hand_over("cafe", film, 3.0)
	game.walker.move = Vector2.ZERO
	camera.target = film.rig


func _on_cue(cue_id: String) -> void:
	match cue_id:
		"hush":
			game.soundscape.set_duck(true)
		"blast":
			game.soundscape.set_duck(false)
			(game.films.of("cafe") as Cinematic).white_flash(0.85)
			game.shake.shake = 1.0
			_goes_off()


func _end_film() -> void:
	game.films.take_back(game.player.body())
	game.soundscape.set_duck(false)
	game.save()


## It goes: the flash and the fire, the street scatters, the coppers in
## earshot come running (the one who saw Danny at the car goes after him),
## and anyone standing too close is hurt.
func _goes_off() -> void:
	var r := game.rackets
	var walker := game.walker
	var at := scene.car_pos
	scene.play_blast()
	_dispatch_emergency(at)
	for s in game.districts.streets():
		s.hear_gunshot(at)
	for o in game.police.officers():
		if o.is_down() or o.body.global_position.distance_to(at) > 1600.0:
			continue
		if r.cafe.seen:
			o.brain.suspect(walker.global_position)  # he saw Danny at the car: a credible reason
		else:
			o.duty = {"pos": at + Vector2(-70, 70), "face": at}  # he comes to look at it, nobody to blame
	if game.player.on_foot() and walker.global_position.distance_to(at) <= CafeJob.DANGER:
		r.cafe.caught_in_it = true
		walker.condition.hurt("torso", 30)
		walker.condition.hurt("left_arm", 20)
		walker.hurt.emit("torso", walker.condition.level("torso"))
	game.save()


## The police car, the fire engine and the ambulance set off for the scene
## along Marlowe Avenue (one after the other) and stay there tonight.
func _dispatch_emergency(at: Vector2) -> void:
	var h: DistrictLayout = game.world.layouts.halloran
	var stops := {}
	for stop in ["police", "fire", "ambulance"]:
		stops[stop] = h.cafe_point("stop_" + stop).pos
	emergency.dispatch(game.rackets.night, game.clock.minute, at, EmergencyResponse.routes_for(h.cafe_point("approach").pos, stops))


## The street is cleared by morning.
func new_night() -> void:
	emergency.clear()


func busy() -> bool:
	return game.films.of("cafe") != null
