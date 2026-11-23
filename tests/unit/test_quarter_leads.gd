extends GutTest
## M015.13 QuarterLeads and their pages (pure): stall insurance found by
## reading, asking and listening, and settled three ways (each paid once,
## Hrabal's thanks once, Kaz's cut once a night); the State's Attorney's man
## told to Rourke or lapsing; the bandleader's card to the Bird or to Rourke
## or lapsing; the case sheets with only what Danny knows and marks where the
## work points; the save.

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new()
	r.money = 2000
	talk = Conversations.new(r)


func _ids(page: Dictionary) -> Array:
	return (page.options as Array).map(func(o: Dictionary) -> String: return o.id)


func _sheet(id: String) -> Dictionary:
	for c in Casebook.cases(r, 1400.0):
		if c.id == id:
			return c
	return {}


func test_stall_insurance_is_found_out_a_piece_at_a_time() -> void:
	var L := r.quarters.leads
	assert_true(_sheet("stall").is_empty(), "nothing known, no sheet")
	var board := talk.open("hall_board", {})
	assert_eq(board.effects, {"quarter": {"lead": "stall"}}, "the notice is news")
	assert_eq(L.stall, QuarterLeads.Stall.SUSPECTED)
	var c := _sheet("stall")
	assert_eq(c.status, Casebook.LEAD, "suspected: a lead")
	assert_true(c.marks.all(func(m: Dictionary) -> bool: return not m.sure), "no sure marks for a suspicion")
	assert_has(c.unknown, "Who \"K.\" is, and where to find him.")
	assert_false(" ".join(c.persons).contains("Kaz"), "nobody has named him yet")
	assert_eq(talk.open("hall_board", {}).effects, {}, "read again: nothing new")
	talk.open("chu", {})
	var named := talk.choose("chu", "who_k", {})
	assert_string_contains(named.text, "Kaz Wrobel")
	assert_eq(L.stall, QuarterLeads.Stall.KNOWN)
	c = _sheet("stall")
	assert_eq(c.status, Casebook.OPEN)
	assert_true(c.marks.any(func(m: Dictionary) -> bool: return m.sure and m.inside == Casebook.KAZ), "a sure mark on Kaz's table")


func test_kaz_keeps_his_hours_and_quits_the_market_when_beaten() -> void:
	var L := r.quarters.leads
	assert_false(L.kaz_in(22.0 * 60.0), "on his rounds at ten")
	assert_true(L.kaz_in(24.0 * 60.0), "at the Lantern at midnight")
	assert_false(L.kaz_in(26.5 * 60.0), "gone home by half past two")
	L.fought_kaz(false)
	assert_eq(L.kaz_fights_lost, 1)
	assert_ne(L.stall, QuarterLeads.Stall.SETTLED, "a lost fight settles nothing")
	L.fought_kaz(true)
	assert_eq(L.stall_how, "beaten")
	assert_false(L.kaz_in(24.0 * 60.0), "he has quit the market")
	assert_eq(L.thanks_due(), 300)
	assert_eq(L.take_thanks(r), 300)
	assert_eq(L.take_thanks(r), 0, "thanked once")
	assert_eq(r.money, 2300)


func test_buying_kaz_off_costs_five_dollars_once() -> void:
	var L := r.quarters.leads
	r.money = 400
	assert_false(L.buy_off_kaz(r), "not without the money")
	assert_eq(r.money, 400)
	r.money = 600
	assert_true(L.buy_off_kaz(r))
	assert_eq(r.money, 100)
	assert_false(L.buy_off_kaz(r), "settled already")
	assert_eq(r.money, 100)
	assert_eq(L.take_thanks(r), 200, "Hrabal's thanks")


func test_in_on_it_a_dollar_a_night_and_no_thanks() -> void:
	r.quarters.leads.hear_stall("chu")
	talk.open("kaz", {})
	talk.choose("kaz", "warn", {})
	var p := talk.choose("kaz", "cut", {})
	assert_eq(r.quarters.leads.stall_how, "cut")
	assert_eq(r.memory.recent("hrabal", "threat", r.night, 1), 1, "Hrabal knows whose friend he is")
	talk.choose("kaz", "collect", {})
	assert_eq(r.money, 2100, "tonight's dollar")
	talk.choose("kaz", "collect", {})
	assert_eq(r.money, 2100, "once a night")
	assert_eq(r.quarters.leads.thanks_due(), 0)
	var cold := talk.open("hrabal", {})
	assert_string_contains(cold.text, "Kaz Wrobel's friend")
	assert_false(_ids(cold).has("thanks"))
	r.end_night()
	var again := talk.open("kaz", {})
	assert_has(_ids(again), "collect", "the next night's dollar")
	assert_eq(_sheet("stall").status, Casebook.OPEN, "his own racket, going on")


func test_kaz_asks_for_a_fight_through_the_game() -> void:
	r.quarters.leads.hear_stall("chu")
	talk.open("kaz", {})
	var w := talk.choose("kaz", "warn", {})
	assert_has(_ids(w), "fists")
	assert_has(_ids(w), "buy")
	assert_has(_ids(w), "cut")
	var f := talk.choose("kaz", "fists", {})
	assert_eq(f.effects, {"fight": "kaz"})


func test_the_state_s_attorney_s_man_from_the_second_night() -> void:
	talk.choose("pratt", "tip", {})
	assert_eq(r.quarters.leads.sa, QuarterLeads.Sa.UNKNOWN, "the first night's dollar buys other gossip")
	r.end_night()
	var tip := talk.choose("pratt", "tip", {})
	assert_string_contains(tip.text, "State's Attorney")
	assert_eq(tip.effects, {"quarter": {"lead": "sa"}})
	assert_eq(_sheet("sa_man").status, Casebook.OPEN)
	var trust := r.boss.trust
	var hello := talk.open("rourke", {})
	assert_has(_ids(hello), "lead_sa", "Danny can tell Rourke")
	var told := talk.choose("rourke", "lead_sa", {})
	assert_string_contains(told.text, "Good eyes")
	assert_eq(r.boss.trust, mini(100, trust + QuarterLeads.TRUST_FOR_SA))
	assert_eq(_sheet("sa_man").status, Casebook.CLOSED)
	assert_false(_ids(talk.open("rourke", {})).has("lead_sa"), "told once")


func test_kept_quiet_the_man_checks_out() -> void:
	r.end_night()
	talk.choose("pratt", "tip", {})
	for i in QuarterLeads.SA_NIGHTS:
		r.end_night()
	assert_eq(r.quarters.leads.sa, QuarterLeads.Sa.LAPSED)
	assert_eq(_sheet("sa_man").status, Casebook.LAPSED)
	assert_false(_ids(talk.open("rourke", {})).has("lead_sa"))


func test_the_bandleader_s_card_to_the_bird() -> void:
	assert_false(_ids(talk.open("bandleader", {})).has("card"), "not before Danny has put a nickel in his cup")
	talk.choose("bandleader", "tune_blue_canal", {})
	assert_has(_ids(talk.open("bandleader", {})), "card")
	talk.choose("bandleader", "card", {})
	var took := talk.choose("bandleader", "take_card", {})
	assert_eq(took.effects, {"quarter": {"lead": "card"}})
	assert_eq(r.money, 2000 - Quarters.TUNE + QuarterLeads.CARD_FEE, "his dollar")
	assert_false(r.quarters.leads.take_card(r), "once ever")
	var bird := talk.open("bird", {})
	assert_has(_ids(bird), "lead_card_bird")
	var gave := talk.choose("bird", "lead_card_bird", {})
	assert_string_contains(gave.text, "nobody owns you")
	assert_eq(r.memory.recent("bird", "favour", r.night, 1), 1, "she remembers it")
	assert_eq(_sheet("bird_card").status, Casebook.CLOSED)


func test_or_to_rourke_and_the_bandleader_knows_who_told() -> void:
	talk.choose("bandleader", "tune_lake_shore", {})
	talk.choose("bandleader", "take_card", {})
	var trust := r.boss.trust
	var hello := talk.open("rourke", {})
	assert_has(_ids(hello), "lead_card_rourke")
	talk.choose("rourke", "lead_card_rourke", {})
	assert_eq(r.boss.trust, mini(100, trust + QuarterLeads.TRUST_FOR_CARD))
	assert_false(_ids(talk.open("bird", {})).has("lead_card_bird"), "the card is Rourke's now")
	assert_string_contains(talk.open("bandleader", {}).text, "Somebody told Rourke")


func test_an_undelivered_card_lapses() -> void:
	talk.choose("bandleader", "tune_lake_shore", {})
	talk.choose("bandleader", "take_card", {})
	for i in QuarterLeads.CARD_NIGHTS:
		r.end_night()
	assert_eq(r.quarters.leads.card, QuarterLeads.Card.LAPSED)
	assert_eq(_sheet("bird_card").status, Casebook.LAPSED)


func test_the_leads_are_saved() -> void:
	var L := r.quarters.leads
	L.hear_stall("board")
	L.hear_stall("chu")
	L.fought_kaz(false)
	L.learn_sa(1)
	L.take_card(r)
	var back := Rackets.new()
	back.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(JSON.stringify(back.quarters.leads.to_dict()), JSON.stringify(L.to_dict()))
	var junk := QuarterLeads.new()
	junk.from_dict({"stall": 99, "stall_how": "stolen", "stall_heard": ["board", "board", "nonsense"], "sa": -3})
	assert_eq(junk.stall, QuarterLeads.Stall.SETTLED, "clamped")
	assert_eq(junk.stall_how, "beaten", "a settled stall has a way it was settled")
	assert_eq(Array(junk.stall_heard), ["board"])
	assert_eq(junk.sa, QuarterLeads.Sa.UNKNOWN)
