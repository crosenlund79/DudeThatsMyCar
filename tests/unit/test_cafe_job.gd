extends GutTest
## M010 Rourke's job at Rosie's Café, without the scene: offered until taken
## on, the parcel wanted only then, Duggan's Packard at the kerb from ten till
## two, the parcel under it only with the job on and the car there, a quarter
## of an hour to the blast, the blast once, the wreck two nights and the
## scorch for good, paid once, saved (a parcel under the car when the game was
## saved has gone off by the time it is loaded); Rourke's pages; the film's
## camera path and captions.

const NIGHT_T := 23 * 60.0


func _rackets() -> Rackets:
	var r := Rackets.new(load("res://src/economy/default_economy.tres"))
	r.money = 2000
	return r


func test_the_course_of_the_job() -> void:
	var c := CafeJob.new()
	assert_true(c.offerable())
	assert_false(c.car_there(1, 21 * 60.0), "not before ten")
	assert_true(c.car_there(1, NIGHT_T))
	assert_false(c.car_there(1, 24 * 60.0 + 150.0), "gone home after two")
	assert_false(c.plant(1, NIGHT_T, false), "not without taking the job on")
	c.offer()
	assert_eq(c.stage, CafeJob.Stage.OFFERED)
	assert_true(c.offerable(), "'not tonight' leaves it open")
	assert_true(c.accept())
	assert_false(c.plant(1, 21 * 60.0, false), "the car is not there yet")
	assert_true(c.plant(1, NIGHT_T, false))
	assert_almost_eq(c.due(1), NIGHT_T + CafeJob.FUSE, 0.01, "a quarter of an hour")
	assert_eq(c.due(2), INF)
	assert_true(c.car_there(1, 24 * 60.0 + 200.0), "with the parcel under it, it waits for it")
	assert_false(c.blast(1, NIGHT_T + 5.0), "not yet")
	assert_true(c.blast(1, NIGHT_T + 15.0))
	assert_false(c.blast(1, NIGHT_T + 20.0), "once only")
	assert_false(c.car_there(1, NIGHT_T + 20.0))
	assert_true(c.wreck_there(1))
	assert_true(c.wreck_there(2))
	assert_false(c.wreck_there(3), "towed after two nights")
	assert_true(c.scorched(), "the scorch stays")
	assert_false(c.offerable(), "never offered again")
	assert_eq(c.report(), CafeJob.REWARD)
	assert_eq(c.report(), 0, "paid once")


func test_saved_and_loaded() -> void:
	var c := CafeJob.new()
	c.accept()
	c.plant(3, NIGHT_T, true)
	var c2 := CafeJob.new()
	c2.from_dict(c.to_dict())
	assert_eq(c2.stage, CafeJob.Stage.DONE, "saved with the parcel under the car: it went off that night")
	assert_true(c2.seen)
	assert_eq(c2.blast_night, 3)
	assert_eq(c2.report(), CafeJob.REWARD)
	var c3 := CafeJob.new()
	c3.from_dict(c2.to_dict())
	assert_eq(c3.report(), 0, "and the payment is remembered")


func test_in_the_books() -> void:
	var r := _rackets()
	assert_false(r.parcel_wanted)
	assert_true(r.take_cafe_job())
	assert_true(r.parcel_wanted, "now Eddie will sell the parcel")
	assert_false(r.plant_parcel(NIGHT_T, false), "no parcel yet")
	assert_true(r.buy_parcel())
	assert_true(r.plant_parcel(NIGHT_T, false))
	assert_eq(r.parcels, 0)
	assert_false(r.parcel_wanted, "no second parcel")
	assert_true(r.cafe_blasted(NIGHT_T + 15.0))
	assert_true(r.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "cafe_blast"), "Halloran Square talks")
	assert_false(r.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "cafe_seen"), "nobody saw him")
	var before := r.money
	assert_eq(r.report_cafe(), CafeJob.REWARD)
	assert_eq(r.money, before + CafeJob.REWARD)
	assert_eq(r.report_cafe(), 0)
	assert_eq(r.money, before + CafeJob.REWARD, "no second payment")
	var r2 := _rackets()
	r2.from_dict(r.to_dict())
	assert_eq(r2.cafe.stage, CafeJob.Stage.REPORTED)


func test_seen_at_the_car() -> void:
	var r := _rackets()
	r.take_cafe_job()
	r.buy_parcel()
	r.plant_parcel(NIGHT_T, true)
	r.cafe_blasted(NIGHT_T + 15.0)
	assert_true(r.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "cafe_seen"), "the copper's word gets about")


func test_rourke_s_pages() -> void:
	var r := _rackets()
	var talk := Conversations.new(r)
	var hello := talk.open("rourke", {})
	var ids: Array = hello.options.map(func(o: Dictionary) -> String: return o.id)
	assert_true(ids.has("cafe"), "he has a job for Danny")
	var offer := talk.choose("rourke", "cafe", {})
	assert_string_contains(offer.text, "Duggan")
	ids = offer.options.map(func(o: Dictionary) -> String: return o.id)
	assert_eq(ids.slice(0, 2), ["cafe_accept", "cafe_later"])
	talk.choose("rourke", "cafe_later", {})
	assert_eq(r.cafe.stage, CafeJob.Stage.OFFERED)
	assert_true(talk.open("rourke", {}).options.any(func(o: Dictionary) -> bool: return o.id == "cafe"), "still on offer")
	var yes := talk.choose("rourke", "cafe_accept", {})
	assert_eq(yes.effects.get("cafe", ""), "accepted")
	assert_true(talk.open("rourke", {}).options.any(func(o: Dictionary) -> bool: return o.id == "cafe_waiting"))
	r.buy_parcel()
	r.plant_parcel(NIGHT_T, false)
	r.cafe_blasted(NIGHT_T + 15.0)
	var done := talk.open("rourke", {})
	assert_true(done.options.any(func(o: Dictionary) -> bool: return o.id == "cafe_report"))
	var paid := talk.choose("rourke", "cafe_report", {})
	assert_eq(int(paid.effects.reward), CafeJob.REWARD)
	assert_false(talk.open("rourke", {}).options.any(func(o: Dictionary) -> bool: return String(o.id).begins_with("cafe")),
		"nothing more to say about it")


func test_the_film_s_path_and_words() -> void:
	var keys := [{"t": 0.0, "pos": Vector2.ZERO, "zoom": 1.0}, {"t": 2.0, "pos": Vector2(100, 0), "zoom": 2.0}]
	assert_eq(Cinematic.rig_at(keys, -1.0).pos, Vector2.ZERO)
	assert_almost_eq((Cinematic.rig_at(keys, 1.0).pos as Vector2).x, 50.0, 0.01, "eased, half way at half time")
	assert_eq(Cinematic.rig_at(keys, 5.0).pos, Vector2(100, 0))
	var caps := [{"t": 0.5, "text": "a"}, {"t": 2.0, "text": "b"}]
	assert_eq(Cinematic.caption_at(caps, 0.1), "")
	assert_eq(Cinematic.caption_at(caps, 1.0), "a")
	assert_eq(Cinematic.caption_at(caps, 3.0), "b")
