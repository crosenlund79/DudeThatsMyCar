class_name Casualties
extends RefCounted
## M014 (from main): who is hurt or down tonight (M006, M012) - Danny hit,
## Danny down (he comes to on Doc Pettibone's table, never killed), someone in
## a room struck down (one of the ward's named people carried off to the Doc's
## for the night; anybody else stays down tonight), and who is out tonight,
## whatever is unloaded and built again. The rules of wounds are the pure
## BodyCondition; this is the game side.

## Doc Pettibone's fee for patching Danny up after he went down (cents, at most).
const COLLAPSE_FEE := 500

var game: Game
## Named people carried off to the Doc's: id -> the night it happened; anybody
## else struck down in a room: "<room>/<id>" -> the night.
var ward_out := {}
## Times Danny went down (for tests).
var collapses := 0


func _init(p_game: Game) -> void:
	game = p_game


func is_out(id: String) -> bool:
	return ward_out.has(id)


## M012: who in a room is out tonight: the named people carried off (by id)
## and anybody else struck down there (by room and id).
func still_out(plan: InteriorPlan) -> Array:
	var out := []
	for p in plan.people:
		if ward_out.has(p.id) or ward_out.has(plan.id + "/" + String(p.id)):
			out.append(p.id)
	return out


## A streamed district's room was built (M012): who goes down in it is seen
## to, and whoever is out tonight is not in it.
func wire_room(v: InteriorView) -> void:
	v.person_down.connect(person_down.bind(v))
	var still := still_out(v.plan)
	if not still.is_empty():
		v.reset_people(still)


## M006: Danny is hit. Where, and how bad, on screen.
func danny_hurt(region: String, level: int) -> void:
	game.player.stand()  # M010: nobody stays sitting when he is hit
	game.back_rooms.danny_hurt()
	game.hud.show_notice("Hit in the %s - %s." % [BodyCondition.NAMES[region], BodyCondition.label(level)])


## M006: Danny goes down. He is not killed: somebody drags him to Doc
## Pettibone's, and he comes to on the examining table an hour later, patched
## up in a hurry (his wounds are grazes now), the Doc's fee taken from his
## pocket (as far as it goes). The night goes on.
func danny_down() -> void:
	var walker := game.walker
	var player := game.player
	var r := game.rackets
	collapses += 1
	game.dialogue.end()
	if not player.on_foot():
		player.eject()  # M008: shot at the wheel
	game.police.stand_down()  # he thinks he got you
	walker.condition.patch_up()
	walker.down = false
	if walker.gun != null:
		walker.gun.holster()
	game.clock.set_time(minf(game.clock.minute + 60.0, float(game.night_rules.dawn_minute)))
	var rival := game.rival
	rival.brain.state = RivalBrain.State.IDLE if not rival.is_down() else rival.brain.state  # he thinks he got you
	var fee := r.pay_doctor(COLLAPSE_FEE)
	var vet := game.ward_plan("vet")
	var spot: Vector2 = vet.spots[0].pos if vet != null else game.layout.spawn
	walker.place(spot, -PI / 2)
	game.interiors.update_player(walker.global_position)
	game.interiors.snap()
	game.camera.snap_to(walker)
	game.hud.set_purse(r.money, r.bottles, r.held)
	game.hud.wake_up(r.night, game.clock.text(), "You came to on Doc Pettibone's table.\nSomebody dragged you in. He took %s for his trouble." % Rackets.dollars(fee))
	game.save()


## M006: someone in a room was struck down. One of the ward's own people (named)
## is carried off to the Doc's for the night - and if Danny did it, the ward
## and Rourke will remember. The Bird down means no more music tonight.
func person_down(id: String, named: bool, view: InteriorView) -> void:
	var r := game.rackets
	var w: Walker = view.people.get(id)
	game.back_rooms.person_down(view.plan.id, id, named)
	if not named:
		ward_out[view.plan.id + "/" + id] = r.night  # M012: stays down tonight, whatever is unloaded or loaded
		return
	ward_out[id] = r.night
	if w != null and w.last_shooter == game.walker:
		r.shot_person(id)
	if id == "bird":
		game.stage.knock_out()
		game.soundscape.stop_music()
	if game.dialogue.talking == id:
		game.dialogue.end()
	game.hud.show_notice("%s goes down, badly hurt. Somebody runs for the Doc." % game.talk.speaker(id))
	game.save()


## A contact in the street struck down (M009): out for the night.
func contact_down(id: String) -> void:
	ward_out[id] = game.rackets.night
	if game.dialogue.talking == id:
		game.dialogue.end()
	game.hud.show_notice("%s goes down, badly hurt. Somebody runs for the Doc." % game.talk.speaker(id))


## Doc Pettibone's treatment paid for (a talk's "heal"): good as new.
func heal(v: Variant) -> void:
	if v:
		game.walker.condition.heal_all()
		game.hud.show_notice("Patched up. Good as new, near enough.")


## Tonight's casualties from the save (an earlier night's are back on their feet).
func load_out(saved: Dictionary, night: int) -> void:
	ward_out = {}
	for id in saved:
		if int(saved[id]) == night:
			ward_out[id] = night


## A new night: everybody back from the Doc's (and they remember).
func new_night() -> void:
	ward_out.clear()
