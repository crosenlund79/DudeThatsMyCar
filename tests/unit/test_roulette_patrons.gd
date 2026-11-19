extends GutTest
## M013.3 the regulars at Leo's wheel (RoulettePatrons, pure): they put their
## own colour chips down through the betting time - never after the call -
## each in their own way (cautious: even money and dozens in nickels and
## dimes; numbers: their numbers; plunger: big chips), within the table's
## limits and their purse; they are settled by the same rules as Danny; their
## purses add up to the cent and never go below nothing; a regular who has
## lost his purse stops; Danny's money and the draw owe nothing to them.

var rules := RouletteRules.new()


func _table(seed := 1, with_patrons := true, patron_seed := 99) -> RouletteTable:
	var t := RouletteTable.new(rules, Roulette.new(rules), seed)
	if with_patrons:
		var p := RoulettePatrons.new(rules, patron_seed)
		for id in ["edna", "stan", "bertie"]:
			p.seat(id)
		t.set_patrons(p)
	return t


func _round_length() -> float:
	return rules.open_seconds + rules.ball_seconds + rules.drop_seconds + rules.result_seconds


func _run(t: RouletteTable, seconds: float, dt := 1.0 / 30.0) -> Array:
	var out := []
	var left := seconds
	while left > 0.0:
		out += t.advance(minf(dt, left))
		left -= dt
	return out


func test_the_roster() -> void:
	var colours := {}
	for id in Patrons.ROSTER:
		var r: Dictionary = Patrons.ROSTER[id]
		assert_ne(String(r.name), "", "%s has a name" % id)
		assert_true(r.game in ["wheel", "slots", "cards"])
		assert_true(r.style in RoulettePatrons.STYLE)
		assert_gt(int(r.purse), 0)
		assert_false(colours.has(r.colour), "%s's chips have a colour of their own" % id)
		colours[r.colour] = true
		for kind in ["win", "big_win", "lose"]:
			assert_false((r[kind] as Array).is_empty(), "%s takes a %s somehow" % [id, kind])


func test_their_chips_go_down_through_the_betting_time_and_never_after() -> void:
	var t := _table()
	var down := 0
	var times := []
	for i in 20:
		for e in _run(t, _round_length(), 1.0 / 60.0):
			pass
	# watch the next rounds event by event
	for f in int(_round_length() * 60.0 * 10.0):
		var open_before := t.betting_open()
		for e in t.advance(1.0 / 60.0):
			if e.event == "patron_bet":
				down += 1
				assert_true(open_before or t.betting_open(), "only while the bets are open")
				times.append(t.round_time)
				assert_lt(t.round_time, t.close_time() + 0.001)
	assert_gt(down, 10, "they play")
	times.sort()
	assert_gt(times.back() - times.front(), 3.0, "not all at once: through the betting time")


func test_each_plays_their_own_way_within_the_limits() -> void:
	var t := _table(3)
	var seen := {"edna": [], "stan": [], "bertie": []}
	for e in _run(t, _round_length() * 60.0):
		if e.event != "patron_bet":
			continue
		seen[e.id].append(e)
		var kind := Roulette.kind_of(e.key)
		assert_true(Roulette.valid(e.key), "%s is a bet on this table" % e.key)
		assert_true(int(e.cents) in rules.chips, "a chip the croupier sells")
	for e in seen.edna:
		assert_true(e.key in RoulettePatrons.STYLE.cautious.keys, "Mrs. Halloway: even money and dozens (%s)" % e.key)
		assert_true(int(e.cents) <= 10, "in nickels and dimes")
	for e in seen.bertie:
		assert_true(Roulette.kind_of(e.key) in ["straight", "split"], "Bertie plays numbers")
		var nums := Roulette.covers(e.key)
		assert_true(nums.any(func(n: int) -> bool: return n in Patrons.ROSTER.bertie.lucky), "his own numbers")
	assert_true(seen.stan.any(func(e: Dictionary) -> bool: return int(e.cents) >= 25), "Big Stan plays big")
	for id in seen:
		assert_false(seen[id].is_empty(), "%s played" % id)


func test_settled_by_the_rules_and_purses_add_up() -> void:
	var t := _table(7)
	var p := t.patrons
	var start := {}
	for id in p.players:
		start[id] = p.purse(id)
	var staked := {}
	var paid := {}
	for e in _run(t, _round_length() * 80.0):
		if e.event == "patron_bet":
			staked[e.id] = int(staked.get(e.id, 0)) + int(e.cents)
		elif e.event == "rest":
			for o in e.others:
				paid[o.id] = int(paid.get(o.id, 0)) + int(o.paid)
	for id in start:
		var on_table := 0
		for key in p.bets.get(id, {}):
			on_table += int(p.bets[id][key])
		assert_eq(p.purse(id) + on_table, int(start[id]) - int(staked.get(id, 0)) + int(paid.get(id, 0)), "%s's purse to the cent" % id)
		assert_gte(p.purse(id), 0, "never below nothing")


func test_their_returns_are_the_tables_returns() -> void:
	var t := _table(21)
	var frozen := {}  # their chips as they stood at the call
	var checked := 0
	for f in int(_round_length() * 30.0 * 30.0):
		for e in t.advance(1.0 / 30.0):
			if e.event == "no_more_bets":
				frozen = {}
				for id in t.patrons.bets:
					frozen[id] = (t.patrons.bets[id] as Dictionary).duplicate()
			elif e.event == "rest":
				var ids := []
				for o in e.others:
					ids.append(o.id)
					var expect := 0
					for key in frozen.get(o.id, {}):
						expect += Roulette.returns(key, int(frozen[o.id][key]), int(e.number))
					assert_eq(int(o.paid), expect, "%s paid by the rules" % o.id)
					checked += 1
				ids.sort()
				var had: Array = frozen.keys()
				had.sort()
				assert_eq(ids, had, "everyone with chips down settled, nobody else")
	assert_gt(checked, 30, "(many settlings checked)")


func test_a_regular_who_has_lost_his_purse_stops() -> void:
	var t := _table(5)
	t.patrons.players.stan.purse = 20  # less than his smallest chip but one
	var bets := 0
	for e in _run(t, _round_length() * 40.0):
		if e.event == "patron_bet" and e.id == "stan":
			bets += 1
	assert_gte(t.patrons.purse("stan"), 0)
	assert_lte(bets, 40, "he plays only while he has it")
	t.patrons.players.stan.purse = 0
	var later := 0
	for e in _run(t, _round_length() * 10.0):
		if e.event == "patron_bet" and e.id == "stan":
			later += 1
	assert_eq(later, 0, "a man with nothing left bets nothing")


func test_dannys_money_and_the_draw_owe_nothing_to_them() -> void:
	var with_them := _table(42, true)
	var without := _table(42, false)
	var money_a := 5000
	var money_b := 5000
	var numbers_a := []
	var numbers_b := []
	for r in 25:
		for pair in [[with_them, "a"], [without, "b"]]:
			var t: RouletteTable = pair[0]
			if pair[1] == "a":
				money_a -= t.danny.place("red", 100, money_a)
				money_a -= t.danny.place("straight:17", 25, money_a)
			else:
				money_b -= t.danny.place("red", 100, money_b)
				money_b -= t.danny.place("straight:17", 25, money_b)
			for e in _run(t, _round_length()):
				if e.event == "rest":
					if pair[1] == "a":
						money_a += int(e.paid)
						numbers_a.append(e.number)
					else:
						money_b += int(e.paid)
						numbers_b.append(e.number)
	assert_eq(numbers_a, numbers_b, "the same numbers with or without the regulars betting")
	assert_eq(money_a, money_b, "and Danny's money the same to the cent")
	assert_gt(with_them.patrons.players.size(), 0)


func test_stepping_away_and_a_new_night() -> void:
	var t := _table(9)
	_run(t, rules.open_seconds + 2.0)
	var p := t.patrons
	var down := 0
	for key in p.bets.get("stan", {}):
		down += int(p.bets.stan[key])
	var purse := p.purse("stan")
	p.unseat("stan")
	assert_eq(p.purse("stan"), purse + down, "chips not yet called back to his purse")
	assert_false("stan" in p.seated())
	for e in _run(t, _round_length() * 3.0):
		if e.event == "patron_bet":
			assert_ne(e.id, "stan", "he no longer plays")
	p.players.edna.purse = 3
	t.begin_night()
	assert_eq(p.purse("edna"), int(Patrons.ROSTER.edna.purse), "fresh money the next night")


func test_the_table_stopping_returns_their_chips() -> void:
	var t := _table(11)
	_run(t, rules.open_seconds + 3.0)
	var p := t.patrons
	var total := 0
	for id in p.players:
		total += p.purse(id)
	total += p.total_down()
	t.halt()
	var after := 0
	for id in p.players:
		after += p.purse(id)
	assert_eq(after, total, "every chip back where it came from")
	assert_eq(p.total_down(), 0)
