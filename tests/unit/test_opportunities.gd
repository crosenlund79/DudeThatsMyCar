extends GutTest
## M009 Danny's own work, from people who are not Rourke: Dutch's crate for
## Novak and the Bijou's lost reel - offered on their own nights, taken or
## left, resolved that night either way, paid modestly and remembered; the
## ward talks, and Rourke hears of it only through the talk.

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())
	talk = Conversations.new(r)


func _ids(page: Dictionary) -> Array:
	return page.options.map(func(o: Dictionary) -> String: return o.id)


func test_which_nights_they_come_up() -> void:
	var crates := []
	var reels := []
	for n in range(1, 13):
		if Opportunities.crate_tonight(n):
			crates.append(n)
		if Opportunities.reel_lost_tonight(n):
			reels.append(n)
	assert_eq(crates.size(), 8, "Dutch has a crate two nights in three")
	assert_eq(reels, [1, 5, 9], "the reel goes missing one night in four")
	assert_eq(r.opportunities.crate, "waiting", "the first night has both")
	assert_eq(r.opportunities.reel, "lost")


func test_left_alone_they_resolve_without_him() -> void:
	var o := r.opportunities
	assert_true(o.advance(22 * 60.0).is_empty())
	var e := o.advance(Opportunities.REEL_SHOW)
	assert_eq(e.map(func(x: Dictionary) -> String: return x.outcome), ["cancelled"], "no reel at eleven: the show is cancelled")
	e = o.advance(Opportunities.CRATE_UNTIL)
	assert_eq(e.map(func(x: Dictionary) -> String: return x.outcome), ["gone"], "Dutch sends it with his nephew")
	assert_true(o.advance(Opportunities.CRATE_DELIVER_BY).is_empty(), "nothing hanging")
	for x in o.history:
		r.opportunity_over(x)
	assert_eq(r.memory.recent("feeney", "broken_promise", r.night), 0, "Danny promised nothing")
	assert_true(r.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "reel_cancelled"), "the square talks anyway")


func test_the_crate_from_dutch_to_novak() -> void:
	var o := r.opportunities
	var hello := talk.open("dutch")
	assert_true(_ids(hello).has("take"))
	assert_true(_ids(hello).has("bye"), "he can say no")
	assert_eq(talk.choose("dutch", "take").effects, {"opportunity": "take_crate"})
	assert_true(o.take_crate())
	assert_false(o.deliver_crate(), "not without loading it")
	assert_true(o.load_crate())
	assert_false(_ids(talk.open("novak", {"crate_outside": false})).has("crate"), "Novak sees no crate")
	assert_true(_ids(talk.open("novak", {"crate_outside": true})).has("crate"))
	assert_eq(talk.choose("novak", "crate", {"crate_outside": true}).effects, {"opportunity": "deliver_crate"})
	var g := r.town.get_business("grocery")
	var till := g.cash
	var stock := g.stock
	var money := r.money
	assert_eq(r.deliver_crate(), Opportunities.CRATE_PAY)
	assert_eq(r.money - money, Opportunities.CRATE_PAY, "four dollars of his own")
	assert_eq(till - g.cash, Opportunities.CRATE_PAY, "out of Novak's till: exact cents")
	assert_gt(g.stock, stock, "and tins on Novak's shelves")
	assert_eq(r.deliver_crate(), 0, "once")
	assert_eq(r.memory.recent("dutch", "kept_promise", r.night), 1)
	assert_false(o.advance(Opportunities.CRATE_DELIVER_BY + 60.0).any(func(e: Dictionary) -> bool: return e.what == "crate"), "done is done")


func test_a_short_till_pays_what_it_has() -> void:
	r.opportunities.take_crate()
	r.opportunities.load_crate()
	var g := r.town.get_business("grocery")
	g.cash = 150
	var money := r.money
	assert_eq(r.deliver_crate(), 150)
	assert_eq(r.money - money, 150)
	assert_eq(g.cash, 0, "no money from nowhere")


func test_a_crate_taken_and_not_delivered() -> void:
	r.opportunities.take_crate()
	r.opportunities.load_crate()
	for e in r.opportunities.advance(Opportunities.CRATE_DELIVER_BY):
		r.opportunity_over(e)
	assert_eq(r.opportunities.crate, "dropped")
	assert_eq(r.memory.recent("dutch", "broken_promise", r.night), 1, "Dutch remembers")
	r.end_night()
	assert_eq(r.opportunities.crate, "waiting", "the next night, another crate")
	assert_string_contains(talk.open("dutch").text, "my crate went for a ride", "and he still offers it, warily")
	r.end_night()
	assert_eq(r.opportunities.crate, "none", "night three: nothing")
	assert_string_contains(talk.open("dutch").text, "people who deliver them")


func test_the_reel_found_and_returned() -> void:
	var o := r.opportunities
	assert_eq(talk.choose("feeney", "take").effects, {"opportunity": "take_reel"})
	o.take_reel()
	assert_false(o.return_reel(), "not before he has found it")
	assert_true(o.find_reel())
	assert_true(_ids(talk.open("feeney")).has("give"))
	var money := r.money
	assert_eq(r.return_reel(), Opportunities.REEL_PAY)
	assert_eq(r.money - money, Opportunities.REEL_PAY)
	assert_eq(r.return_reel(), 0, "paid once")
	assert_eq(r.memory.recent("feeney", "kept_promise", r.night), 1)
	assert_true(o.advance(Opportunities.REEL_SHOW).is_empty(), "the show went on")


func test_found_without_being_asked() -> void:
	assert_true(r.opportunities.find_reel(), "a film can behind a church: he picks it up")
	assert_true(_ids(talk.open("feeney")).has("give"))
	assert_eq(r.return_reel(), Opportunities.REEL_PAY)
	assert_eq(r.memory.recent("feeney", "kept_promise", r.night), 0, "no promise to keep")
	assert_eq(r.memory.recent("feeney", "favour", r.night), 1)


func test_a_reel_promised_and_not_brought() -> void:
	r.opportunities.take_reel()
	for e in r.opportunities.advance(Opportunities.REEL_SHOW):
		r.opportunity_over(e)
	assert_eq(r.memory.recent("feeney", "broken_promise", r.night), 1)
	assert_string_contains(talk.open("feeney").text, "Some help you were")


func test_rourke_hears_of_it_through_talk_and_minds_his_envelopes() -> void:
	var control := Rackets.new(EconomyRules.new())  # the same two nights without the crate
	r.opportunities.take_crate()
	r.opportunities.load_crate()
	r.deliver_crate()
	control.end_night()
	control.end_night()
	r.end_night()  # Novak tells Augie
	assert_true(r.boss.heard.is_empty(), "not yet")
	r.end_night()  # Augie tells Rourke
	assert_eq(r.boss.heard.size(), 1)
	assert_string_contains(r.boss.heard[0].text, "hauling crates")
	assert_eq(r.boss.trust, control.boss.trust, "his own time is his own: no betrayal")
	assert_eq(r.boss.patience, control.boss.patience)
	var news := talk.choose("rourke", "news")
	assert_string_contains(news.text, "Your own time's your own business")
	assert_string_contains(talk._talk_line(r.rumours.known_to("sal", "crate_run")[0]), "hauling crates", "and the ward talks of it")


func test_only_his_own_money_no_envelope() -> void:
	# what Danny earns on his own does not add to what Rourke expects
	var expect_before: int = r.boss.expected
	r.opportunities.take_crate()
	r.opportunities.load_crate()
	r.deliver_crate()
	r.return_reel()
	assert_eq(r.boss.expected, expect_before)


## M013: a game saved mid-night goes on from where it stood (M012 resumes the
## clock at the saved minute; M009 started the night again at dusk).
func test_a_saved_night_goes_on_from_where_it_stood() -> void:
	r.opportunities.take_reel()
	r.opportunities.find_reel()
	r.return_reel()
	r.opportunities.take_crate()
	var d := r.to_dict()
	var again := Rackets.new(EconomyRules.new())
	again.from_dict(JSON.parse_string(JSON.stringify(d)))
	assert_eq(again.opportunities.reel, "returned", "what is over tonight stays over")
	assert_eq(again.opportunities.crate, "taken", "the crate Danny took on is still his to load")
	assert_eq(again.return_reel(), 0, "and is not paid twice")
	again.opportunities.load_crate()
	var third := Rackets.new(EconomyRules.new())
	third.from_dict(JSON.parse_string(JSON.stringify(again.to_dict())))
	assert_eq(third.opportunities.crate, "loaded", "in the boot it stays")
	assert_gt(third.deliver_crate(), 0)
	assert_eq(third.deliver_crate(), 0, "paid once")
