extends GutTest
## M014: the registries that replaced main's knowledge of every feature -
## Dialogue applies a page's effects in one fixed order whoever registered
## them first, one handler an effect, one call a hook; Missions registers each
## job's effects and fights once and calls every hook in the order the jobs
## were added (the M007-M012 clock order).


class Spy extends JobDirector:
	var name := ""
	var log: Array
	var fx := {}
	var fights_of := {}

	func _init(g: Game, n: String, l: Array) -> void:
		super(g)
		name = n
		log = l

	func id() -> String:
		return name

	func effects() -> Dictionary:
		return fx

	func fights() -> Dictionary:
		return fights_of

	func setup() -> void:
		log.append(name + ":setup")

	func clock(minute: float, _delta: float) -> void:
		log.append("%s:clock:%d" % [name, int(minute)])

	func district_ready(d: String, _l: DistrictLayout, _n: Node2D) -> void:
		log.append(name + ":ready:" + d)

	func district_unloading(d: String) -> void:
		log.append(name + ":unloading:" + d)

	func rooms_built() -> void:
		log.append(name + ":rooms")

	func new_night() -> void:
		log.append(name + ":night")

	func restored() -> void:
		log.append(name + ":restored")


func _game() -> Game:
	var g := Game.new()
	g.dialogue = Dialogue.new(g)
	return g


func test_effects_apply_in_the_fixed_order_whoever_registered_first() -> void:
	var g := _game()
	var seen := []
	var keys := Dialogue.EFFECTS.duplicate()
	keys.reverse()  # registered back to front
	for key in keys:
		assert_true(g.dialogue.on_effect(key, func(v: Variant, _e: Dictionary) -> void: seen.append([key, v])))
	var effects := {}
	for key in keys:
		effects[key] = key + "!"
	g.dialogue.apply(effects)
	assert_eq(seen.map(func(e: Array) -> String: return e[0]), Dialogue.EFFECTS, "M003-M012 order")
	assert_eq(seen[0][1], Dialogue.EFFECTS[0] + "!", "each with its value")
	seen.clear()
	g.dialogue.apply({"police": true, "incident": "hush"})
	assert_eq(seen, [["incident", "hush"], ["police", true]], "only the effects on the page, still in order")


func test_one_handler_an_effect_one_call_a_hook() -> void:
	var g := _game()
	var first := []
	assert_true(g.dialogue.on_effect("heal", func(v: Variant, _e: Dictionary) -> void: first.append(v)))
	assert_false(g.dialogue.on_effect("heal", func(_v: Variant, _e: Dictionary) -> void: fail_test("second handler ran")),
		"a second handler is refused")
	assert_false(g.dialogue.on_effect("no_such_effect", func(_v: Variant, _e: Dictionary) -> void: pass),
		"an effect Dialogue does not apply is refused")
	g.dialogue.apply({"heal": true})
	assert_eq(first, [true], "the first one, once")
	var hook := func(_who: String) -> void: pass
	assert_true(g.dialogue.on_end(hook))
	assert_false(g.dialogue.on_end(hook), "the same end hook twice is refused")


func test_missions_register_and_call_in_order() -> void:
	var g := _game()
	var m := Missions.new(g)
	var log := []
	var a := Spy.new(g, "a", log)
	var b := Spy.new(g, "b", log)
	var applied := []
	a.fx = {"job": func(v: Variant, _e: Dictionary) -> void: applied.append("a:" + String(v))}
	b.fx = {"freight": func(v: Variant, _e: Dictionary) -> void: applied.append("b:" + String(v))}
	var started := []
	a.fights_of = {"lefty": func() -> void: started.append("lefty")}
	b.fights_of = {"walt": func() -> void: started.append("walt")}
	m.add(a)
	m.add(b)
	m.add(a)  # twice: refused
	assert_eq(m.jobs.size(), 2)
	assert_eq(m.get_job("b"), b)
	g.dialogue.apply({"freight": "fee", "job": "next"})
	assert_eq(applied, ["b:fee", "a:next"], "the jobs' effects in Dialogue's order (freight before job)")
	m.fight_starter("walt").call()
	assert_eq(started, ["walt"])
	assert_false(m.fight_starter("nobody").is_valid())
	m.setup()
	m.clock(1300.0, 0.1)
	m.district_ready("yards", null, null)
	m.rooms_built()
	m.district_unloading("yards")
	m.new_night()
	m.restored()
	assert_eq(log, ["a:setup", "b:setup", "a:clock:1300", "b:clock:1300", "a:ready:yards", "b:ready:yards", "a:rooms",
		"b:rooms", "a:unloading:yards", "b:unloading:yards", "a:night", "b:night", "a:restored", "b:restored"])


func test_a_fight_or_an_effect_two_jobs_claim_goes_to_the_first() -> void:
	var g := _game()
	var m := Missions.new(g)
	var log := []
	var a := Spy.new(g, "a", log)
	var b := Spy.new(g, "b", log)
	var who := []
	a.fights_of = {"lefty": func() -> void: who.append("a")}
	b.fights_of = {"lefty": func() -> void: who.append("b")}
	a.fx = {"cafe": func(_v: Variant, _e: Dictionary) -> void: who.append("a-cafe")}
	b.fx = {"cafe": func(_v: Variant, _e: Dictionary) -> void: who.append("b-cafe")}
	m.add(a)
	m.add(b)
	m.fight_starter("lefty").call()
	g.dialogue.apply({"cafe": "reported"})
	assert_eq(who, ["a", "a-cafe"])


func test_the_game_wires_six_jobs_none_twice() -> void:
	# the real directors, without a scene: the effects they claim never overlap
	var g := _game()
	var m := Missions.new(g)
	for j in [RourkeJobDirector.new(g), Errands.new(g), FreightJobDirector.new(g), CafeJobDirector.new(g), LastSong.new(g)]:
		m.add(j)
	assert_eq(m.jobs.map(func(j: JobDirector) -> String: return j.id()), ["rourke", "errands", "freight", "cafe", "last_song"],
		"the M007-M012 clock order")
	var claimed := {}
	for j in m.jobs:
		for key in j.effects():
			assert_false(claimed.has(key), key + " claimed twice")
			claimed[key] = j.id()
	assert_eq(claimed, {"job": "rourke", "opportunity": "errands", "freight": "freight", "parcel": "cafe", "cafe": "cafe",
		"bird_scene": "last_song"})
	assert_true(m.fight_starter("lefty").is_valid())
	assert_true(m.fight_starter("walt").is_valid())
