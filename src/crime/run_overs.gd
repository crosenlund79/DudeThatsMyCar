class_name RunOvers
extends JobDirector
## M015: a car Danny drives knocks somebody down (Car.struck_person, through
## the Fleet). The person is hurt by how hard it hit them (Walker.hit_by_car):
## a clip, a hard knock, or worse. Then the consequences, as for a shooting:
## the people near enough to see it scatter; a copper who saw it comes for him
## - with his revolver out for anything worse than a clip, and the copper who
## was struck always knows; a named person remembers it and the talk goes
## round; for a stranger the talk starts with the nearest local who could have
## seen it (not for a mere clip). The rest is decided where it always was:
## Lefty turns on him, a contact is carried off to the Doc's, a passer-by
## killed stays down for the night, a copper killed is a new man tomorrow.

## People this near see it and scatter (px).
const SCATTER := 320.0
## The nearest local within this saw or heard it (px).
const LOCAL_SEES := 700.0
## From this closing speed (px/s) it is a hard knock, not a clip.
const SERIOUS := 150.0

var game: Game
## What happened last (for the notice and tests): {who, impact, killed, seen}.
var last := {}
## How many people Danny's cars knocked down tonight.
var tonight := 0


func _init(p_game: Game) -> void:
	game = p_game


func id() -> String:
	return "run_overs"


func setup() -> void:
	game.fleet.person_struck.connect(struck)


func new_night() -> void:
	tonight = 0


## `car` struck `person` at `impact` px/s.
func struck(car: Car, person: Walker, impact: float) -> void:
	if person == game.walker or person.down:
		return
	var danny := game.player != null and game.player.car == car
	person.hit_by_car(car.model.velocity, impact, car.global_position, game.walker if danny else null)
	if not danny:
		return
	tonight += 1
	var at := person.global_position
	var who := who_is(person)
	var killed := person.down
	var serious := killed or impact >= SERIOUS
	var seen := false
	for o in game.police.officers():
		if o.body == person:
			if not person.down:
				o.witness_run_down(at, car.global_position, true, true)
			seen = true
		elif o.witness_run_down(at, car.global_position, serious):
			seen = true
	for s in game.districts.streets():
		s.scare(at, SCATTER)
	if who == "" and serious:
		var local := _local_near(at)
		if local != "":
			var layout := game.world.layout_at(at)
			var place := layout.place_name(at) if layout != null else ""
			game.rackets.ran_down_stranger(local, "on " + place if place != "" else "in the street", killed)
	last = {"who": who, "impact": impact, "killed": killed, "seen": seen}
	game.hud.show_notice(_notice(who, impact, killed))


## Who `person` is: "lefty", "copper", a contact's id - or "" for a stranger.
func who_is(person: Walker) -> String:
	if game.rival != null and person == game.rival.body:
		return "lefty"
	for o in game.police.officers():
		if o.body == person:
			return "copper"
	return String(person.get_meta("person", ""))


func _notice(who: String, impact: float, killed: bool) -> String:
	var name := "a passer-by"
	if who == "copper":
		name = "the copper"
	elif who != "":
		name = game.talk.speaker(who) if who != "lefty" else "Lefty Moran"
	if killed:
		return "You ran down %s. Nobody gets up from that." % name
	if impact >= SERIOUS:
		return "You knocked %s flat - badly hurt." % name
	return "You clipped %s with the car." % name


## The named local nearest `at` who could have seen it (an incident spot's
## local within LOCAL_SEES), "" if none.
func _local_near(at: Vector2) -> String:
	var layout := game.world.layout_at(at)
	if layout == null:
		return ""
	var best := ""
	var best_d := LOCAL_SEES
	for spot in layout.incident_spots:
		var local := String(spot.get("local", ""))
		var d := at.distance_to(spot.pos)
		if local != "" and d < best_d:
			best_d = d
			best = local
	return best
