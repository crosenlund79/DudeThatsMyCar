extends GutTest
## M012 who calls out to Danny (pure): from what they remember and what the
## talk has told them, never from what they cannot know; once a person a
## night, not two calls close together, a line not said again for some nights
## (business may come back); never while Danny is busy or guns are going off;
## the state saved. And where Quilty and Leon are by the hour.

var r: Rackets
var c: Callouts


func before_each() -> void:
	r = Rackets.new(EconomyRules.new())
	c = r.callouts


func _ctx(extra: Dictionary = {}) -> Dictionary:
	return {"minute": 20 * 60.0, "near": 80.0, "singing": false}.merged(extra, true)


func test_rourke_calls_when_he_has_business_once_a_night() -> void:
	var id := c.pick("rourke", _ctx({"rourke_business": true}), r)
	assert_eq(id, "rourke_business")
	c.mark(id, 20 * 60.0)
	assert_eq(c.pick("rourke", _ctx({"rourke_business": true, "minute": 23 * 60.0}), r), "", "once tonight")
	assert_eq(c.pick("rourke", _ctx({"rourke_business": false}), r), "")
	r.end_night()
	assert_eq(c.pick("rourke", _ctx({"rourke_business": true}), r), "rourke_business", "business comes back the next night")


func test_nobody_calls_while_danny_is_busy_or_guns_go_off() -> void:
	for busy in ["driving", "talking", "busy", "film", "fighting", "menu"]:
		assert_eq(c.pick("quilty", _ctx({busy: true}), r), "", busy)
	assert_eq(c.pick("quilty", _ctx({"since_gunfire": 4.0}), r), "", "a shot a moment ago")
	assert_eq(c.pick("quilty", _ctx({"near": Callouts.RANGE + 10.0}), r), "", "too far off")
	assert_eq(c.pick("quilty", _ctx({"present": false}), r), "", "not there")
	assert_eq(c.pick("quilty", _ctx({"since_gunfire": 60.0}), r), "quilty_hello")


func test_calls_do_not_crowd_each_other() -> void:
	c.mark(c.pick("quilty", _ctx(), r), 20 * 60.0)
	assert_eq(c.pick("leon", _ctx({"minute": 20 * 60.0 + 5.0}), r), "", "not right after another")
	assert_eq(c.pick("leon", _ctx({"minute": 20 * 60.0 + Callouts.GAP_MINUTES + 1.0}), r), "leon_job", "Leon, with his trouble")


func test_a_line_is_not_said_again_for_some_nights() -> void:
	c.mark(c.pick("quilty", _ctx(), r), 20 * 60.0)
	for n in Callouts.REPEAT_NIGHTS - 1:
		r.end_night()
		assert_eq(c.pick("quilty", _ctx(), r), "", "night %d: no new greeting" % r.night)
	r.end_night()
	assert_eq(c.pick("quilty", _ctx(), r), "quilty_hello", "after a while, a hello again")


func test_augie_remembers_a_threat_and_stays_wary() -> void:
	r.memory.remember("augie", "threat", r.night)
	assert_eq(c.pick("augie", _ctx(), r), "augie_wary")
	r.end_night()
	assert_eq(c.pick("augie", _ctx(), r), "augie_wary", "not friendly overnight")
	var calm := Rackets.new(EconomyRules.new())
	for i in 3:
		calm.memory.remember("augie", "favour", calm.night)
	if not calm.club().is_short():
		assert_eq(calm.callouts.pick("augie", _ctx(), calm), "augie_warm", "a friend: warm")


func test_quilty_knows_only_what_the_talk_brings_him() -> void:
	r.shot_person("sal")
	assert_eq(c.pick("quilty", _ctx(), r), "quilty_hello", "the night of it, he has not heard")
	r.end_night()  # Sal knows -> the talk goes round a step a night
	r.end_night()
	assert_true(r.rumours.known_to("quilty", "shot").size() > 0, "by now it has reached him")
	assert_eq(c.pick("quilty", _ctx(), r), "quilty_shooting", "and he says so")


func test_the_bird_does_not_call_from_the_middle_of_a_song() -> void:
	assert_eq(c.pick("bird", _ctx({"singing": true}), r), "")
	assert_eq(c.pick("bird", _ctx(), r), "bird_hello")
	r.memory.remember("bird", "interrupted", r.night)
	assert_eq(c.pick("bird", _ctx(), r), "bird_again", "she remembers who stopped her song")


func test_saved_and_loaded() -> void:
	c.mark(c.pick("quilty", _ctx(), r), 20 * 60.0)
	var copy := Rackets.new(EconomyRules.new())
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(copy.callouts.pick("quilty", _ctx({"minute": 23 * 60.0}), copy), "", "already called tonight")
	assert_eq(copy.callouts.said, {"quilty_hello": r.night})


func test_every_line_has_its_words_and_its_delivery() -> void:
	for id in Callouts.LINES:
		var line: Dictionary = Callouts.LINES[id]
		for k in ["who", "call", "follow", "reply", "tag"]:
			assert_ne(String(line.get(k, "")), "", "%s: %s" % [id, k])
		assert_false(String(line.call).contains("["), "%s: no stage directions in the words" % id)


func test_routines_by_the_hour() -> void:
	assert_true(Routines.in_room("quilty", 23 * 60.0))
	assert_eq(Routines.where("quilty", 25 * 60.0 + 5.0), "home", "home to bed after one")
	assert_eq(Routines.where("leon", 23 * 60.0), "room")
	assert_eq(Routines.where("leon", 24 * 60.0 + 10.0), "dutch", "coffee at Dutch's after midnight")
	assert_eq(Routines.where("leon", 24 * 60.0 + 30.0), "room", "back at his desk")
	assert_eq(Routines.where("rourke", 26 * 60.0), "room", "the others keep their place")
