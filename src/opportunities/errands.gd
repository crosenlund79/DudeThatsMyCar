class_name Errands
extends JobDirector
## M014 (from main): the game side of Danny's own work in the street (M009) -
## Dutch's crate (the Yards: loaded into a car's boot, driven to Novak's) and
## the Bijou's reel (Halloran Square: the film can in the churchyard): their
## contacts and errands (OpportunityViews, made with their district), talking
## to them, loading and finding, delivering and returning, and the clock
## running them out. Which nights, the pay and the memory are the pure
## Opportunities (in Rackets).

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## Dutch, Mr. Feeney, the crate and the film can where they are built.
var views: OpportunityViews


func id() -> String:
	return "errands"


## The views, made where main made them (M009).
func build() -> OpportunityViews:
	views = OpportunityViews.new()
	views.setup(game.resolver, game.rackets)
	views.is_out = game.casualties.is_out
	views.contact_hurt.connect(_on_contact_hurt)
	views.contact_down.connect(func(id: String, _w: Walker) -> void: game.casualties.contact_down(id))
	return views


func effects() -> Dictionary:
	return {"opportunity": func(v: Variant, _e: Dictionary) -> void: _opportunity(String(v))}


## The talk's context: is a car with the crate in it at Novak's door?
func setup() -> void:
	game.dialogue.on_context(func() -> Dictionary: return {"crate_outside": game.fleet.crate_car_at(novak_door()) != null})


func district_ready(id: String, layout: DistrictLayout, node: Node2D) -> void:
	views.district_ready(id, layout, node)


func district_unloading(id: String) -> void:
	views.district_gone(id)


## Dutch, Mr. Feeney or an errand within reach: what E would do there.
func spot(at: Vector2) -> Dictionary:
	var op := views.near(at) if views != null else {}
	if not op.is_empty():
		op["prompt"] = {"dutch": "Talk to Dutch", "feeney": "Talk to Mr. Feeney", "crate": "Load the crate into a car",
			"film_can": "Pick up the film can"}.get(op.id, "Talk")
	return op


func use(spot: Dictionary) -> void:
	if spot.get("kind", "") == "contact":
		var w := views.contact(spot.id)
		if w != null:
			w.aim_point = game.walker.global_position
		game.dialogue.open(spot.id)
	elif spot.get("kind", "") == "errand":
		take_errand(spot.id, spot.pos)


## E at an errand: Dutch's crate goes into the boot of the car at the kerb;
## the Bijou's film can into Danny's coat.
func take_errand(errand: String, at: Vector2) -> void:
	var r := game.rackets
	var hud := game.hud
	match errand:
		"crate":
			var best := game.fleet.loadable_car_near(at, OpportunityViews.LOAD_REACH)
			if best == null:
				hud.show_notice("You'll want a car up at the kerb for that. It's a heavy crate.")
				return
			if r.opportunities.load_crate():
				game.fleet.set_cargo(best, true)
				game.soundscape.play("vehicles/door", -3.0)
				hud.show_notice("You and Dutch heave the crate into the boot. Novak's Grocery, before two.")
				game.save()
		"film_can":
			if r.opportunities.find_reel():
				hud.show_notice("A flat tin film can, \"BIJOU - LATE\" chalked on the lid. Mr. Feeney's reel.")
				game.save()


func _opportunity(what: String) -> void:
	var r := game.rackets
	match what:
		"take_crate":
			r.opportunities.take_crate()
		"take_reel":
			r.opportunities.take_reel()
		"deliver_crate":
			var c := game.fleet.crate_car_at(novak_door())
			if c != null and r.deliver_crate() >= 0:
				game.fleet.set_cargo(c, false)
				game.hud.show_notice("Dutch's crate delivered.")
		"return_reel":
			if r.return_reel() > 0:
				game.hud.show_notice("The late show goes on at the Bijou.")


## The clock: too late is too late (M009).
func clock(minute: float, _delta: float) -> void:
	for e in game.rackets.opportunities.advance(minute):
		opportunity_over(e)


## An opportunity ran out on its own (the clock): remembered and talked about;
## if Danny had taken it on, he is told.
func opportunity_over(e: Dictionary) -> void:
	var r := game.rackets
	var promised: bool = e.what == "crate" and e.outcome == "dropped" or e.what == "reel" and r.opportunities.reel_promised
	r.opportunity_over(e)
	match [e.what, e.outcome]:
		["crate", "dropped"]:
			for c in game.fleet.cars:
				game.fleet.set_cargo(c, false)
			game.hud.show_notice("Two o'clock. Novak's shut - Dutch's nephew will be fetching his crate.")
		["reel", "cancelled"]:
			if promised:
				game.hud.show_notice("Eleven o'clock. No reel at the Bijou - the late show's off.")


## M013: a game saved before the cars were (or with no car carrying it): Dutch's
## crate loaded into a boot that is not there any more goes back to the kerb, to
## be loaded again, rather than being lost.
func restored() -> void:
	var r := game.rackets
	if r.opportunities.crate == "loaded" and not game.fleet.any_cargo():
		r.opportunities.crate = "taken"


## The views' signals call back into this job: let them go with it.
func release() -> void:
	views = null


## In front of Novak's Grocery, where the crate is delivered.
func novak_door() -> Vector2:
	var g := game.ward_plan("grocery")
	return g.outside_door(0, 20.0) if g != null else Vector2.INF


## M009: Dutch or Mr. Feeney hit: if Danny did it, they (and the talk) remember.
func _on_contact_hurt(id: String, w: Walker) -> void:
	var r := game.rackets
	if w.last_shooter == game.walker and w.last_cause == "car":
		if r.memory.recent(id, "run_down", r.night, 1) == 0:
			r.ran_down(id, false)  # M015: Danny's car, not his gun
	elif w.last_shooter == game.walker and r.memory.recent(id, "shot", r.night, 1) == 0:
		r.shot_person(id)
