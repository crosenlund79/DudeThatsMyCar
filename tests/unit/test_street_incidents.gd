extends GutTest
## M009 the city's own small troubles as plain state: each night has its own
## plan (the same night, the same plan), incidents begin, go through their
## phases and end on the clock with nobody watching, never more than two at
## once, never two on one stretch of pavement, never begun right beside Danny;
## Danny stepping in changes how one ends; a reloaded night does not repeat
## what is over.

const START := 19.0 * 60.0 + 30.0
const DAWN := 29.0 * 60.0 + 30.0

var city: StreetIncidents


func before_each() -> void:
	var all := CityPlan.layouts(RiversideWard.create())
	city = StreetIncidents.new(StreetIncidents.spots_of(all))
	city.begin_night(1, START, DAWN)


## Runs the night minute by minute to `until`; returns every event.
func _run(until: float, danny: Vector2 = Vector2.INF, can_stop: Callable = Callable()) -> Array:
	var events := []
	var m := city.minute
	while m < until:
		m += 1.0
		events.append_array(city.advance(m, danny, can_stop))
		assert_lte(city.active.size(), StreetIncidents.MAX_ACTIVE, "never more than two at once")
		for i in city.active.size():
			for j in range(i + 1, city.active.size()):
				assert_gt((city.active[i].spot.pos as Vector2).distance_to(city.active[j].spot.pos), StreetIncidents.APART - 1.0)
	return events


func test_every_district_has_somewhere_for_each_kind() -> void:
	for district in ["riverside", "yards", "halloran"]:
		for kind in StreetIncidents.KINDS:
			assert_true(city.spots.any(func(s: Dictionary) -> bool: return s.district == district and (s.kinds as Array).has(kind)),
				"%s has a place for a %s" % [district, kind])
	for s in city.spots:
		var l: DistrictLayout = null
		for d in CityPlan.layouts(RiversideWard.create()):
			if d.id == s.district:
				l = d
		for side in [-1.0, 1.0]:
			var p: Vector2 = s.pos + (s.along as Vector2) * 24.0 * side
			assert_true(l.is_open_ground(p, 10.0), "%s: room for two people at %s" % [s.id, p])


func test_each_night_has_its_own_plan_and_the_same_night_the_same() -> void:
	var first := city.plan.duplicate(true)
	assert_gte(first.size(), 5, "a handful of incidents a night")
	assert_lte(first.size(), 12, "not a crowd of them")
	var again := StreetIncidents.new(city.spots)
	again.begin_night(1, START, DAWN)
	assert_eq(again.plan, first, "the same night, the same plan")
	again.begin_night(2, START, DAWN)
	assert_ne(again.plan.map(func(p: Dictionary) -> String: return p.spot), first.map(func(p: Dictionary) -> String: return p.spot))
	for i in range(1, first.size()):
		assert_gte(float(first[i].at) - float(first[i - 1].at), StreetIncidents.GAP_MIN - 0.01, "spaced out")
		assert_ne(first[i].kind, first[i - 1].kind, "not the same thing twice in a row")
		assert_true((city.spot(first[i].spot).kinds as Array).has(first[i].kind), "each at a place that suits it")


func test_the_city_gets_on_with_it_while_danny_is_elsewhere() -> void:
	var events := _run(DAWN)
	var started := events.filter(func(e: Dictionary) -> bool: return e.event == "started")
	var over := events.filter(func(e: Dictionary) -> bool: return e.event == "over")
	assert_gte(started.size(), 4)
	assert_eq(over.size(), started.size(), "everything that began came to an end")
	assert_eq(city.active, [], "nothing left hanging at dawn")
	for e in over:
		var inc: Dictionary = e.incident
		assert_ne(inc.outcome, "", "%s ended somehow" % inc.id)
		assert_eq(inc.mercer, "", "without Danny")
		assert_true(["settled", "blows", "done", "released", "taken_in"].has(inc.outcome), inc.outcome)
	assert_eq(city.history.size(), over.size())


func test_phases_in_order() -> void:
	var p: Dictionary = city.plan[0]
	_run(float(p.at) + 0.5)
	var inc := city.get_incident(p.id)
	assert_false(inc.is_empty(), "it began on time")
	var names := [city.phase_name(inc)]
	for i in 120:
		_run(city.minute + 1.0)
		if inc.phase >= (StreetIncidents.PHASES[inc.kind] as Array).size():
			break
		if city.phase_name(inc) != names.back():
			names.append(city.phase_name(inc))
	var expected: Array = StreetIncidents.PHASES[p.kind].map(func(ph: Array) -> String: return ph[0])
	assert_eq(names, expected, "a beginning, a middle and an end")


func test_never_begun_right_beside_danny() -> void:
	var p: Dictionary = city.plan[0]
	var at: Vector2 = city.spot(p.spot).pos
	_run(float(p.at) + 5.0, at + Vector2(100, 0))
	assert_true(city.get_incident(p.id).is_empty(), "not staged in front of him")
	assert_true(city.plan.any(func(q: Dictionary) -> bool: return q.id == p.id), "put off, not dropped")
	_run(float(p.at) + StreetIncidents.POSTPONE + 2.0)
	assert_false(city.get_incident(p.id).is_empty(), "it happens once he has gone")


func test_a_stop_waits_for_a_free_copper() -> void:
	var stops := city.plan.filter(func(q: Dictionary) -> bool: return q.kind == "stop")
	if stops.is_empty():
		city.begin_night(3, START, DAWN)
		stops = city.plan.filter(func(q: Dictionary) -> bool: return q.kind == "stop")
	var p: Dictionary = stops[0]
	_run(float(p.at) + 2.0, Vector2.INF, func(_d: String) -> bool: return false)
	assert_true(city.get_incident(p.id).is_empty(), "the beat cop is busy")


func test_stepping_in_changes_the_ending() -> void:
	var p: Dictionary = city.plan[0]
	_run(float(p.at) + 1.0)
	var choice: String = {"argument": "calm", "exchange": "cut", "stop": "bribe"}[p.kind]
	var out := city.intervene(p.id, choice)
	assert_true(out.ok)
	assert_eq(out.outcome, {"argument": "broken_up", "exchange": "hushed", "stop": "bribed"}[p.kind])
	assert_false(city.intervene(p.id, choice).ok, "once")
	var inc := city.get_incident(p.id)
	assert_eq(inc.phase, (StreetIncidents.PHASES[p.kind] as Array).size() - 1, "straight to its end")
	_run(city.minute + 10.0)
	var h: Dictionary = city.history.filter(func(x: Dictionary) -> bool: return x.id == p.id)[0]
	assert_eq(h.outcome, out.outcome)
	assert_eq(h.mercer, choice)
	assert_eq(StreetIncidents.reading(inc).talk, "street_%s_%s" % [p.kind, out.outcome], "it gets talked about")


func test_robbing_needs_a_gun() -> void:
	city.begin_night(1, START, DAWN)
	var ex := city.plan.filter(func(q: Dictionary) -> bool: return q.kind == "exchange")
	var p: Dictionary = ex[0]
	_run(float(p.at) + 1.0)
	assert_eq(city.intervene(p.id, "rob", {"gun_drawn": false}).outcome, "spoiled", "empty hands: they just bolt")


func test_the_same_incident_ends_the_same_way() -> void:
	_run(DAWN)
	var first := city.history.duplicate(true)
	var again := StreetIncidents.new(city.spots)
	again.begin_night(1, START, DAWN)
	var m := START
	while m < DAWN:
		m += 7.0
		again.advance(m)
	assert_eq(again.history.map(func(h: Dictionary) -> String: return h.outcome), first.map(func(h: Dictionary) -> String: return h.outcome),
		"deterministic, however the clock steps")


func test_a_reloaded_night_does_not_repeat_what_is_over() -> void:
	var total := city.plan.size()
	var p: Dictionary = city.plan[0]
	_run(float(p.at) + 60.0)
	assert_eq(city.history.size(), 1)
	var saved := city.to_dict()
	var again := StreetIncidents.new(city.spots)
	again.begin_night(1, START, DAWN, StreetIncidents.saved_history(saved, 1))
	assert_false(again.plan.any(func(q: Dictionary) -> bool: return q.id == p.id), "it does not happen twice")
	assert_eq(again.plan.size(), total - 1, "the rest of the night is still to come (it begins again at dusk)")
	assert_eq(StreetIncidents.saved_history(saved, 2), [], "a new night starts afresh")
