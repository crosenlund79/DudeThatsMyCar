extends GutTest
## M010 Eddie's Thompson and the parcel, without the scene: the Thompson fires
## while the trigger is held at its cadence (the pistol never does), its kick
## builds up and settles, its own magazine and spare rounds; the loan (deposit,
## the fee kept, never twice, overdue after a few nights, saved); the parcel
## (only when the job wants it, once, for its price, saved); Eddie's pages.

const DT := 1.0 / 60.0


func _run(g: Gun, seconds: float) -> PackedStringArray:
	var all := PackedStringArray()
	for i in int(round(seconds / DT)):
		all.append_array(g.step(DT))
	return all


func _count(events: PackedStringArray, what: String) -> int:
	return Array(events).count(what)


func _rackets() -> Rackets:
	var r := Rackets.new(load("res://src/economy/default_economy.tres"))
	r.money = 2000
	return r


func test_held_down_it_keeps_firing() -> void:
	var g := Gun.new(load("res://src/weapons/thompson.tres"))
	assert_eq(g.ammo, 20)
	assert_eq(g.spare, 40)
	g.trigger()
	g.held = true
	var ev := _run(g, 0.35 + 1.0)  # drawn, then a second with the trigger held
	var shots := _count(ev, "fired")
	assert_between(shots, 9, 12, "about ten rounds a second while held (%d)" % shots)
	g.held = false
	assert_eq(_count(_run(g, 0.5), "fired"), 0, "let go: it stops")
	assert_eq(g.ammo, 20 - shots)
	# empty the stick: it reloads from its own spare rounds
	g.held = true
	ev = _run(g, 3.0)
	assert_true(Array(ev).has("reload"))
	g.held = false
	_run(g, 3.0)
	assert_eq(g.ammo, 20)
	assert_eq(g.spare, 20)


func test_the_kick_builds_and_settles() -> void:
	var g := Gun.new(load("res://src/weapons/thompson.tres"))
	g.trigger()
	g.held = true
	_run(g, 1.0)
	assert_gt(g.kick, 3.0, "a burst climbs")
	assert_lte(g.kick, g.rules.recoil_max)
	g.held = false
	_run(g, 2.0)
	assert_almost_eq(g.kick, 0.0, 0.01, "and settles")


func test_the_pistol_is_one_shot_a_click() -> void:
	var g := Gun.new(load("res://src/weapons/default_pistol.tres"))
	g.trigger()
	g.held = true
	assert_eq(_count(_run(g, 1.5), "fired"), 1, "holding the button fires the .45 once")
	assert_eq(g.kick, 0.0)


func test_the_loan() -> void:
	var r := _rackets()
	r.money = 400
	assert_false(r.borrow_thompson(), "no five dollars, no Thompson")
	r.money = 2000
	assert_true(r.borrow_thompson())
	assert_eq(r.money, 1500, "five dollars down")
	assert_true(r.loan.out)
	assert_false(r.borrow_thompson(), "only one to lend")
	assert_eq(r.money, 1500)
	assert_false(r.loan.overdue(r.night + 2))
	assert_true(r.loan.overdue(r.night + 3), "three nights and Eddie wants it back")
	var saved := r.to_dict()
	var r2 := _rackets()
	r2.from_dict(saved)
	assert_true(r2.loan.out, "still on loan after a save")
	assert_eq(r2.loan.ammo, GunLoan.LOADED)
	assert_eq(r.return_thompson(), 400, "the deposit less Eddie's dollar")
	assert_eq(r.money, 1900)
	assert_false(r.loan.out)
	assert_eq(r.return_thompson(), 0, "nothing to give back twice")
	assert_eq(r.memory.entries.eddie.map(func(e: Dictionary) -> String: return e.kind), ["lent_thompson", "returned_thompson"],
		"Eddie remembers")


func test_the_parcel() -> void:
	var r := _rackets()
	assert_false(r.buy_parcel(), "nobody sells one without the job")
	r.parcel_wanted = true
	r.money = 500
	assert_false(r.buy_parcel(), "six dollars")
	r.money = 1000
	assert_true(r.buy_parcel())
	assert_eq(r.money, 400)
	assert_eq(r.parcels, 1)
	assert_false(r.buy_parcel(), "one at a time")
	var r2 := _rackets()
	r2.from_dict(r.to_dict())
	assert_eq(r2.parcels, 1, "carried through a save")
	assert_true(r2.parcel_wanted)


func test_eddie_s_pages() -> void:
	var r := _rackets()
	var talk := Conversations.new(r)
	var wares := talk.choose("eddie", "wares", {"spare": 7})
	var ids: Array = wares.options.map(func(o: Dictionary) -> String: return o.id)
	assert_false(ids.has("parcel"), "no parcel on offer without the job")
	var heavy := talk.choose("eddie", "heavy", {})
	assert_eq(heavy.options[0].id, "borrow")
	var lent := talk.choose("eddie", "borrow", {})
	assert_eq(lent.effects.get("thompson", ""), "lent")
	assert_eq(r.money, 1500)
	var hello := talk.open("eddie", {})
	ids = hello.options.map(func(o: Dictionary) -> String: return o.id)
	assert_true(ids.has("give_back"))
	assert_string_contains(talk.choose("eddie", "heavy", {}).text, "under your coat already")
	r.night += 3
	assert_string_contains(talk.open("eddie", {}).text, "Bring her home", "overdue")
	var back := talk.choose("eddie", "give_back", {})
	assert_eq(back.effects.get("thompson", ""), "returned")
	r.parcel_wanted = true
	wares = talk.choose("eddie", "wares", {"spare": 7})
	ids = wares.options.map(func(o: Dictionary) -> String: return o.id)
	assert_true(ids.has("parcel"))
	var bought := talk.choose("eddie", "parcel", {})
	assert_eq(bought.effects.get("parcel", 0), 1)
	assert_eq(r.parcels, 1)
