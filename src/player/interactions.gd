class_name Interactions
extends RefCounted
## M014 (from main): what E does where Danny stands on foot - the spot (one of
## thirteen kinds, asked in one fixed order: the Bird asking him to stay, the
## room's own spots, Lefty, standing up or sitting down, the cafe's Packard,
## Leon at Dutch's, Dutch and Mr. Feeney and their errands, an incident, a
## door, a locked door), what pressing E there does (handed to the part of the
## game it belongs to), the prompt on the HUD and the ring under what E would
## act on (M012). The order is the M003-M012 order and must stay so: when two
## spots overlap, the first wins.

## M012: a person's ring is wider than his figure (drawn under it).
const PERSON_RING := 24.0

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## The interaction spot the player stands at (on foot): someone to talk to or
## the bed inside a room, else a door to go in or out by; {} when none.
## M006: nobody to talk to who is down or carried off; Lefty in the street.
func spot() -> Dictionary:
	var player := game.player
	if not player.on_foot():
		return {}
	var at := game.walker.global_position
	# M012: the Bird off the bandstand, asking him to stay (before the room's own spots)
	var bird := game.last_song.spot(at)
	if not bird.is_empty():
		return bird
	var interiors := game.interiors
	if interiors.current != null:
		var s := interiors.current.spot_at(at)
		if not s.is_empty() and (s.id == "bed" or s.id == "poker" or Conversations.is_readable(s.id) or interiors.view_of(interiors.current.id).person_ok(s.id)):
			return s
		if not s.is_empty() and (s.id == "roulette" or String(s.id).begins_with("slot_")):
			return s  # M011: the wheel (whether Leo is there to spin it is said when you step up), the machines
	var lefty := game.rourke_job.spot(at)
	if not lefty.is_empty():
		return lefty
	# M010: sitting: up again, or a seat to sit on
	if not player.seat.is_empty():
		return {"id": "stand", "prompt": "Stand up      Space (hold)   Let the time pass"}
	var seat := Seats.near(game.districts.seats_near(), at)
	if not seat.is_empty():
		return {"id": "seat", "seat": seat, "prompt": "Sit down"}
	# M010: Duggan's Packard, with the parcel in Danny's coat
	var plant := game.cafe.spot(at)
	if not plant.is_empty():
		return plant
	# M012: Leon at Dutch's counter, his coffee after midnight
	var leon := game.people.leon_spot(at)
	if not leon.is_empty():
		return leon
	# M009: Dutch, Mr. Feeney and their errands
	var op := game.errands.spot(at)
	if not op.is_empty():
		return op
	# M009: one of the city's incidents going on right here
	var views := game.incident_views
	var inc := views.incident_near(at, 48.0) if views != null else {}
	if not inc.is_empty() and inc.mercer == "" and inc.phase < (StreetIncidents.PHASES[inc.kind] as Array).size() - 1:
		return {"id": "incident", "incident": inc.id,
			"prompt": {"argument": "Step in", "exchange": "Walk over", "stop": "Have a word with the officer"}[inc.kind]}
	var door := interiors.door_at(at)
	if not door.is_empty():
		door["id"] = "door"
		return door
	# M011: a door shut for the night that can be tried (City Hall, the mayor's gate, the aldermen)
	var world := game.world
	var here := world.layout_at(at) if world != null else game.layout
	var locked := here.locked_door_at(at) if here != null else {}
	if not locked.is_empty():
		return {"id": "locked", "prompt": locked.prompt, "text": locked.text, "talk": locked.get("talk", ""), "pos": locked.pos}
	return door


## E on foot at a spot: what is there gets it. Returns true when used.
func use(_at: Vector2) -> bool:
	var s := spot()
	var hud := game.hud
	var player := game.player
	var walker := game.walker
	if s.is_empty():
		if player.enterable_car() == null and game.districts.scenery_truck_near(walker.global_position):
			# M010: the yards' works trucks are scenery; say so, and where a truck can be had
			hud.show_notice("The cab's chained and padlocked for the night. Brennan's coal truck on Wharf Street is another story.")
			return true
		return false
	var dialogue := game.dialogue
	if s.id == "door":
		game.soundscape.play_door(s.plan)
		game.interiors.step_through(walker, s)
	elif s.id == "bird":
		game.club.talk_to_bird()
	elif s.id == "lefty":
		game.rourke_job.use(s)
	elif s.id == "seat":
		player.sit(s.seat)
	elif s.id == "poker":
		game.back_rooms.open_poker()
	elif s.id == "roulette":
		game.back_rooms.open_roulette()
	elif String(s.id).begins_with("slot_"):
		game.back_rooms.open_slot(int(String(s.id).substr(5)))
	elif s.id == "plant":
		game.cafe.use(s)
	elif s.id == "locked" and s.talk != "":
		dialogue.start(s.talk)  # M012: the bell at the Mayor's gate brings someone down the path
	elif s.id == "locked":
		game.soundscape.play("places/door", -10.0)  # the handle rattles; nobody comes
		hud.show_notice(s.text)
	elif s.id == "stand":
		player.stand()
	elif s.get("routine", false):
		dialogue.start(s.id)  # M012: Leon at Dutch's
	elif s.id == "bird_scene":
		game.last_song.use(s)
	elif s.get("kind", "") == "contact" or s.get("kind", "") == "errand":
		game.errands.use(s)
	elif s.id == "incident":
		dialogue.incident_talking = s.incident
		dialogue.open("incident")
	elif s.id == "bed" or Conversations.is_readable(s.id) or not game.interiors.current.person(s.id).is_empty():
		dialogue.start(s.id)
	return true


## The prompt on the HUD this frame (and the ring under what E would act on).
func prompt() -> String:
	var player := game.player
	var walker := game.walker
	var out := ""
	var target := {}
	if game.back_rooms.at_a_table():
		pass
	elif player.on_foot():
		var s := spot()
		var c := player.enterable_car()
		if game.dialogue.talking == "" and player.seat.is_empty():
			target = highlight_for(s, c)  # M012
		if not s.is_empty():
			out = "E   %s" % ("Interrupt the Bird" if s.id == "bird" and game.stage.singing() else s.prompt)
		elif c == null and game.districts.scenery_truck_near(walker.global_position):
			out = "A works truck - chained up for the night"
		elif c != null:
			out = game.fleet.prompt_for(c)
	elif player.car.speed() < 30.0:
		out = "E   Get out"
	game.highlight.show_target(target)
	return out


## M012: what the ring goes under - the thing E would act on now (the spot
## the prompt names, or the car he would get into) - or {} for nothing.
func highlight_for(s: Dictionary, c: Car) -> Dictionary:
	var walker := game.walker
	if s.is_empty():
		if c != null and not game.districts.scenery_truck_near(walker.global_position):
			return {"kind": "car", "xform": c.global_transform, "size": c.vehicle.size}
		return {}
	var id := String(s.id)
	match id:
		"door":
			var plan: InteriorPlan = s.plan
			var i: int = s.index
			var side: Vector2 = plan.doors[i].side
			var centre := plan.door_centre(i) + side * InteriorPlan.WALL * 0.5
			var along := side.orthogonal() * float(plan.doors[i].width) * 0.5
			return {"kind": "door", "a": centre - along, "b": centre + along}
		"locked":
			return {"kind": "ring", "pos": s.pos, "radius": 13.0, "cold": String(s.get("talk", "")) == ""}
		"lefty":
			return {"kind": "ring", "pos": game.rival.body.global_position, "radius": PERSON_RING}
		"seat":
			return {"kind": "ring", "pos": s.seat.pos, "radius": 16.0}
		"stand":
			return {}
		"plant":
			return {"kind": "ring", "pos": game.cafe.scene.car_pos, "radius": 30.0}
	if s.get("kind", "") == "contact":
		var w := game.errands.views.contact(id)
		return {"kind": "ring", "pos": w.global_position, "radius": PERSON_RING} if w != null else {}
	var interiors := game.interiors
	if interiors.current != null:
		var person := interiors.person(interiors.current.id, id)
		if person != null:
			return {"kind": "ring", "pos": person.global_position, "radius": PERSON_RING}
	if s.has("pos"):
		return {"kind": "ring", "pos": s.pos, "radius": 12.0}
	return {}
