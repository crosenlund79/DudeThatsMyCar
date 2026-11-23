extends GutTest
## M015 Danny's case sheets (Casebook, pure): a sheet for each piece of
## business he knows of - things, persons, places, what he knows, what he
## doesn't, his leads - growing as he learns and never ahead of him; settled
## business kept as a closed case; marks for where the work points (sure for
## what he knows he must do, unsure for a hunch, none for hidden work), every
## one a real place in the city.


func _rackets() -> Rackets:
	var r := Rackets.new(EconomyRules.new())
	r.opportunities.crate = "none"
	r.opportunities.reel = "none"
	return r


func _case(r: Rackets, id: String, minute := 21 * 60.0) -> Dictionary:
	for c in Casebook.cases(r, minute):
		if String(c.id) == id:
			return c
	return {}


func _all_text(c: Dictionary) -> String:
	var parts: Array = [c.title, c.standing]
	for k in ["things", "persons", "places", "known", "unknown", "leads"]:
		parts.append_array(c[k])
	return " | ".join(parts.map(func(x: Variant) -> String: return String(x)))


func test_nothing_known_nothing_written() -> void:
	assert_eq(Casebook.cases(_rackets(), 21 * 60.0), [])


func test_rourkes_job_grows_as_danny_learns() -> void:
	var r := _rackets()
	r.job.stage = RourkeJob.Stage.OFFERED
	var c := _case(r, "rourke_lindqvist")
	assert_eq(c.status, Casebook.OPEN)
	assert_false(_all_text(c).contains("Lefty"), "nobody has told him who yet")
	assert_eq(c.unknown.size(), 1)
	assert_eq(c.marks[0].at, Casebook.OWL_DOOR, "Rourke wants an answer")
	r.job.stage = RourkeJob.Stage.ACCEPTED
	c = _case(r, "rourke_lindqvist")
	assert_string_contains(String(c.leads[0]), "Lindqvist")
	assert_eq([c.marks[0].at, c.marks[0].inside], [Casebook.HARDWARE_DOOR, Casebook.LINDQVIST])
	r.job.learn("culprit")
	c = _case(r, "rourke_lindqvist")
	assert_string_contains(_all_text(c), "Lefty Moran")
	assert_string_contains(_all_text(c), "Pruitt Street")
	assert_eq(c.marks[0].at, Casebook.LEFTY)
	assert_true((c.unknown as Array).any(func(u: String) -> bool: return u.contains("fight")), "how he fights: not yet")
	r.job.learn("tip")
	c = _case(r, "rourke_lindqvist")
	assert_string_contains(_all_text(c), "left shoulder", "Eddie's tip, once he has it")
	r.job.outcome = "backed_down"
	c = _case(r, "rourke_lindqvist")
	assert_eq(c.marks[0].inside, Casebook.ROURKE, "then: tell Rourke")
	r.job.stage = RourkeJob.Stage.REPORTED
	r.job.told = "backed_down"
	r.job.verdict = "pleased"
	c = _case(r, "rourke_lindqvist")
	assert_eq(c.status, Casebook.CLOSED, "kept in the book, closed")
	assert_string_contains(String(c.standing), "pleased")
	assert_eq(Casebook.marks([c]), [], "a closed case points nowhere")


func test_a_lie_keeps_the_case_open() -> void:
	var r := _rackets()
	r.job.stage = RourkeJob.Stage.REPORTED
	r.job.learn("culprit")
	r.job.told = "handled"
	var c := _case(r, "rourke_lindqvist")
	assert_eq(c.status, Casebook.OPEN)
	assert_string_contains(String(c.standing), "It isn't")


func test_hidden_work_stays_hidden_until_danny_knows_the_man() -> void:
	var r := _rackets()
	r.opportunities.crate = "waiting"
	r.opportunities.reel = "lost"
	assert_eq(Casebook.cases(r, 21 * 60.0), [], "never met Dutch or Mr. Feeney: no marks, no sheet")
	r.memory.remember("dutch", "deal", r.night)
	var c := _case(r, "crate_%d" % r.opportunities.night)
	assert_eq(c.status, Casebook.LEAD, "a hunch")
	var m := Casebook.marks([c])
	assert_eq(m.size(), 1)
	assert_false(m[0].sure, "a dashed ring, a pale mark")
	assert_eq(_case(r, "crate_%d" % r.opportunities.night, Opportunities.CRATE_UNTIL + 5.0), {}, "after half past eleven: gone")


func test_an_errand_taken_is_open_and_then_closed() -> void:
	var r := _rackets()
	r.opportunities.crate = "taken"
	var c := _case(r, "crate_%d" % r.opportunities.night)
	assert_eq(c.status, Casebook.OPEN)
	assert_eq(c.marks[0].at, Casebook.CRATE)
	assert_true(Casebook.marks([c])[0].sure)
	r.opportunities.crate = "loaded"
	assert_eq(_case(r, "crate_%d" % r.opportunities.night).marks[0].inside, Casebook.NOVAK)
	r.opportunities.crate = "delivered"
	r.opportunities.history.append({"night": r.opportunities.night, "what": "crate", "outcome": "delivered"})
	c = _case(r, "crate_%d" % r.opportunities.night)
	assert_eq(c.status, Casebook.CLOSED, "delivered: kept for reference")


func test_the_reel_where_he_was_told_and_no_further() -> void:
	var r := _rackets()
	r.opportunities.reel = "looking"
	var c := _case(r, "reel_%d" % r.opportunities.night)
	assert_string_contains(_all_text(c), "St. Brendan's")
	assert_true((c.unknown as Array).any(func(u: String) -> bool: return u.contains("Exactly where")), "not the spot itself")
	r.opportunities.reel = "found"
	assert_eq(_case(r, "reel_%d" % r.opportunities.night).marks[0].at, Casebook.FEENEY)


func test_leons_freight() -> void:
	var r := _rackets()
	r.freight.offer(r.night, 23 * 60.0)
	var c := _case(r, "freight")
	assert_true((c.unknown as Array).any(func(u: String) -> bool: return u.contains("Why")))
	assert_false(_all_text(c).contains("Walt Haney -"), "not who holds it up")
	r.freight.stage = FreightJob.Stage.ACCEPTED
	r.freight.learn("docked")
	c = _case(r, "freight")
	assert_string_contains(_all_text(c), "docked Walt's gang six dollars")
	assert_eq(c.marks[0].inside, Casebook.WALT)
	r.freight.stage = FreightJob.Stage.PAID
	assert_eq(_case(r, "freight").status, Casebook.CLOSED)


func test_open_business_comes_first_then_hunches_then_old_cases() -> void:
	var r := _rackets()
	r.job.stage = RourkeJob.Stage.DECLINED
	r.memory.remember("feeney", "deal", r.night)
	r.opportunities.reel = "lost"
	r.loan.out = true
	var order := Casebook.cases(r, 21 * 60.0).map(func(c: Dictionary) -> String: return String(c.status))
	assert_eq(order, [Casebook.OPEN, Casebook.LEAD, Casebook.CLOSED])


func test_every_mark_is_a_real_place() -> void:
	var places := CityLocations.of(CityPlan.layouts(RiversideWard.create()))
	for id in [Casebook.ROURKE, Casebook.OWL_DOOR, Casebook.HARDWARE_DOOR, Casebook.LINDQVIST, Casebook.EDDIE, Casebook.LEFTY,
			Casebook.GROCERY_DOOR, Casebook.NOVAK, Casebook.CAFE_CAR, Casebook.CAFE_BENCH, Casebook.DUTCH, Casebook.CRATE,
			Casebook.FEENEY, Casebook.FILM_CAN, Casebook.DISPATCH_DOOR, Casebook.LEON, Casebook.SHED_DOOR, Casebook.WALT,
			Casebook.UNION_BOARD]:
		assert_true(places.has(id), id)
