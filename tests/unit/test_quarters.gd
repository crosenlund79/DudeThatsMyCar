extends GutTest
## M015.12 Quarters and QuarterTalk (pure): the new quarters' people and what
## Danny can do with them - each purchase paid once in exact cents, with its
## nightly limit, never below nothing and never given back; the coffee's lift
## on the night's drowsiness; the band's tunes; the pages and their effects;
## a new night; the save.

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new()
	r.money = 1000
	talk = Conversations.new(r)


func _ids(page: Dictionary) -> Array:
	return (page.options as Array).map(func(o: Dictionary) -> String: return o.id)


func test_coffee_is_a_nickel_twice_a_night() -> void:
	var q := r.quarters
	assert_true(q.buy_coffee(r, 1500.0))
	assert_eq(r.money, 995)
	assert_true(q.buy_coffee(r, 1520.0))
	assert_eq(r.money, 990)
	assert_false(q.buy_coffee(r, 1530.0), "two cups is enough")
	assert_eq(r.money, 990, "nothing taken for a refusal")
	r.money = 3
	r.quarters.begin_night(2)
	assert_false(r.quarters.buy_coffee(r, 1500.0), "no nickel, no coffee")
	assert_eq(r.money, 3)


func test_the_coffee_holds_the_heaviness_off_and_wears_off() -> void:
	var q := r.quarters
	assert_eq(q.lift(1700.0), 0.0, "no coffee tonight")
	q.buy_coffee(r, 1700.0)
	assert_almost_eq(q.lift(1700.0), Quarters.COFFEE_LIFT, 0.001)
	assert_almost_eq(q.lift(1700.0 + Quarters.COFFEE_WEARS / 2.0), Quarters.COFFEE_LIFT / 2.0, 0.001)
	assert_eq(q.lift(1700.0 + Quarters.COFFEE_WEARS + 1.0), 0.0, "worn off")
	var clock := NightClock.new(load("res://src/night/default_night.tres"))
	clock.set_time(float(clock.rules.drowsy_minute) + 30.0)
	var heavy := clock.drowsiness()
	assert_gt(heavy, 0.0)
	clock.held_off = q.lift(1700.0)
	assert_lt(clock.drowsiness(), heavy, "held off")
	clock.held_off = Quarters.COFFEE_LIFT
	assert_eq(clock.drowsiness(), 0.0, "30 minutes in, 40 held off: not drowsy yet")


func test_feld_sells_one_box_at_his_price_and_never_more_than_he_can_carry() -> void:
	var q := r.quarters
	var limit := r.rules.spare_limit
	assert_eq(q.feld_rounds(r, limit), 0, "pockets full: no sale")
	assert_eq(q.buy_feld_rounds(r, limit), 0)
	assert_eq(r.money, 1000)
	assert_eq(q.feld_rounds(r, limit - 5), 5, "only what fits")
	assert_eq(q.buy_feld_rounds(r, 0), r.rules.ammo_box, "a box of Eddie's size")
	assert_eq(r.money, 1000 - Quarters.FELD_BOX)
	assert_eq(q.buy_feld_rounds(r, 0), 0, "one box a night")
	assert_eq(r.money, 1000 - Quarters.FELD_BOX)
	assert_gt(Quarters.FELD_BOX, r.rules.ammo_price, "dearer than Eddie")


func test_dances_meals_requests_and_the_tip() -> void:
	var q := r.quarters
	for i in Quarters.DANCES:
		assert_true(q.dance(r))
	assert_false(q.dance(r), "three a night")
	assert_eq(r.money, 1000 - Quarters.DANCES * Quarters.TICKET)
	assert_true(q.buy_meal(r))
	assert_false(q.buy_meal(r), "one plate a night")
	var before := r.money
	assert_false(q.request(r, q.tune), "not the tune already playing")
	assert_false(q.request(r, "no_such_tune"))
	assert_eq(r.money, before)
	assert_true(q.request(r, "lake_shore"))
	assert_eq(q.tune, "lake_shore")
	assert_eq(r.money, before - Quarters.TUNE)
	assert_true(q.tip(r))
	assert_false(q.tip(r), "once a night is discretion")
	assert_eq(r.money, before - Quarters.TUNE - Quarters.TIP)
	r.money = 0
	q.begin_night(2)
	assert_false(q.dance(r))
	assert_false(q.buy_meal(r))
	assert_false(q.tip(r))
	assert_eq(r.money, 0, "never below nothing")


func test_a_new_night_starts_the_limits_afresh_and_the_save_keeps_tonight() -> void:
	var q := r.quarters
	q.buy_coffee(r, 1600.0)
	q.dance(r)
	q.meet("ruby")
	q.request(r, "after_midnight")
	var copy := Quarters.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(q.to_dict())))
	assert_eq(JSON.stringify(copy.to_dict()), JSON.stringify(q.to_dict()), "round trip")
	assert_eq(copy.coffees, 1)
	assert_eq(copy.tune, "after_midnight")
	assert_true(copy.met.has("ruby"))
	r.end_night()
	assert_eq(r.quarters.night, 2)
	assert_eq(r.quarters.coffees, 0)
	assert_eq(r.quarters.dances, 0)
	assert_eq(r.quarters.coffee_at, -1.0)
	assert_true(r.quarters.met.has("ruby"), "she remembers him")
	var saved := r.to_dict()
	var back := Rackets.new()
	back.from_dict(JSON.parse_string(JSON.stringify(saved)))
	assert_eq(JSON.stringify(back.quarters.to_dict()), JSON.stringify(r.quarters.to_dict()), "in the rackets' save")
	var old := Rackets.new()
	old.from_dict({"money": 500, "night": 4})
	assert_eq(old.quarters.night, 4, "a save from before M015.12 starts the quarters on its night")


func test_every_new_person_has_a_page_and_a_way_out() -> void:
	for who in QuarterTalk.PEOPLE:
		var p := talk.open(who, {"spare": 0, "minute": 1400.0})
		assert_false(p.is_empty(), who)
		assert_eq(p.speaker, QuarterTalk.NAMES[who])
		assert_has(_ids(p), "bye", "%s can be left" % who)
	for what in QuarterTalk.READS:
		assert_true(Conversations.is_readable(what))
		var p := talk.open(what, {})
		assert_true(p.get("narrated", false), what)


func test_the_pages_take_the_money_once_and_ask_the_game_for_the_rest() -> void:
	talk.open("dvorak", {"minute": 1500.0})
	var p := talk.choose("dvorak", "coffee", {"minute": 1500.0})
	assert_eq(p.effects, {"quarter": {"coffee": true}})
	assert_eq(r.money, 995)
	p = talk.choose("feld", "rounds", {"spare": 0})
	assert_eq(p.effects, {"rounds": r.rules.ammo_box})
	assert_eq(r.money, 995 - Quarters.FELD_BOX)
	p = talk.choose("feld", "rounds", {"spare": 0})
	assert_false(p.has("effects") and (p.effects as Dictionary).has("rounds"), "the second box is refused")
	assert_eq(r.money, 995 - Quarters.FELD_BOX)
	p = talk.choose("ruby", "ticket", {})
	assert_eq(p.effects, {"quarter": {"dance": true}})
	assert_string_contains(p.text, "Fay")
	p = talk.choose("bandleader", "tune_blue_canal", {})
	assert_eq(p.effects, {"quarter": {"tune": "blue_canal"}})
	var b := talk.open("bandleader", {})
	assert_false(_ids(b).has("tune_blue_canal"), "not offered the tune already playing")
	p = talk.choose("pratt", "who", {})
	assert_has(_ids(p), "tip")
	p = talk.choose("pratt", "tip", {})
	assert_eq(r.money, 995 - Quarters.FELD_BOX - Quarters.TICKET - Quarters.TUNE - Quarters.TIP)
	assert_false(_ids(talk.choose("pratt", "who", {})).has("tip"), "once a night")


func test_chu_passes_on_what_is_said_about_danny() -> void:
	talk.open("chu", {})
	var plain := talk.choose("chu", "eat", {})
	assert_eq(r.money, 1000 - Quarters.MEAL)
	assert_true(plain.text.contains(QuarterTalk.LANTERN_TALK[0].substr(0, 20)), "the Lantern's own news while nobody talks of him")
	r.rumours.start("favour", "novak", r.night, {"business": "grocery"})
	var told := talk.choose("chu", "talk", {})
	assert_string_contains(told.text, "table four")
	assert_string_contains(told.text, "helped out")


func test_first_meetings_are_remembered() -> void:
	var first := talk.open("hrabal", {})
	assert_string_contains(first.text, "clean shoes")
	var again := talk.open("hrabal", {})
	assert_string_contains(again.text, "Back again")
	assert_eq(r.quarters.met.hrabal, 1)
