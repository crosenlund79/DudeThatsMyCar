class_name IncidentDirector
extends RefCounted
## M014 (from main): the city's small troubles (M009) in the game - they move
## on with the clock wherever Danny is; one that ends is talked about by
## whoever saw it; a police stop breaks off if its copper is called away
## (gunfire) or down; Danny steps into one through a talk; the minimap points
## out the ones he has noticed (M010). The rules are the pure StreetIncidents
## and IncidentNotice; the people are IncidentViews.

## M009: what stepping in brings or costs (cents).
const HUSH_MONEY := 200
const HANDOFF_TAKE := 600

## An incident began, moved on or ended ("started", "phase", "over").
signal incident_event(event: String, incident: Dictionary)

var game: Game
## The incidents Danny has noticed (by noise or sight): id -> true.
var noticed := {}


func _init(p_game: Game) -> void:
	game = p_game


## The clock moved on: stops whose copper is busy break off; the plan moves on.
func advance() -> void:
	var incidents := game.incidents
	var player := game.player
	var danny := player.body().global_position if player != null else Vector2.INF
	for inc in incidents.active.duplicate():
		if inc.kind == "stop" and inc.mercer == "" and incidents.phase_name(inc) != "leaving" \
				and game.world.is_ready(inc.spot.district):
			var cop := game.police.officer_of(inc.spot.district)
			if cop == null or cop.brain.is_hunting():
				if cop != null:
					cop.duty = {}
				end(incidents.break_off(inc.id, "broken_off"))
	for e in incidents.advance(game.clock.minute, danny, game.police.can_stop):
		if e.event == "over":
			game.rackets.street_incident_over(e.incident)
		incident_event.emit(e.event, e.incident)


## An incident ended early (broken off): talked about like any other.
func end(e: Dictionary) -> void:
	if e.is_empty():
		return
	game.rackets.street_incident_over(e.incident)
	incident_event.emit("over", e.incident)


## Danny steps into the incident he is talking his way into (see Conversations).
func step_in(choice: String) -> void:
	var incidents := game.incidents
	var dialogue := game.dialogue
	var inc := incidents.get_incident(dialogue.incident_talking)
	if inc.is_empty():
		return
	var out := incidents.intervene(inc.id, choice, dialogue.context())
	if not out.ok:
		return
	var r := game.rackets
	match out.outcome:
		"hushed":
			r.money += HUSH_MONEY
		"robbed":
			r.money += HANDOFF_TAKE
			game.police.witness_violence(game.walker.global_position, game.walker.global_position)  # a hold-up at gunpoint, if a copper saw it
		"bribed":
			r.money -= mini(Conversations.STOP_BRIBE, r.money)
		"vouched":
			var cop := game.police.officer_of(inc.spot.district)
			if cop != null:
				cop.duty = {}
				cop.brain.suspect(game.walker.global_position)
	incident_event.emit("phase", inc)


## M010: the incidents Danny has noticed (by noise or sight), so the minimap
## can point them out: a ping when he first notices one in its range, an arrow
## on its rim while one in this district goes on out of it.
func notice() -> void:
	var hud := game.hud
	if hud == null or hud.minimap == null:
		return
	var incidents := game.incidents
	var danny := game.player.body().global_position
	var arrows: Array[Vector2] = []
	for inc in incidents.active:
		if String(inc.spot.district) != game.world.current:
			continue
		if not noticed.has(inc.id) and IncidentNotice.noticed(inc, incidents.phase_name(inc), danny):
			noticed[inc.id] = true
			if hud.minimap.place_on_map(inc.spot.pos).on_map:
				hud.minimap.ping(inc.spot.pos)
		if noticed.has(inc.id) and not hud.minimap.place_on_map(inc.spot.pos).on_map:
			arrows.append(inc.spot.pos)
	hud.minimap.set_arrows(arrows)
	for id in noticed.keys():
		if incidents.get_incident(id).is_empty():
			noticed.erase(id)


## Shots near an incident: its people break off and run.
func hear_gunshot(muzzle: Vector2) -> void:
	var views := game.incident_views
	if views != null:
		for e in views.hear_gunshot(muzzle):  # M009: they break off and run
			end(e)
