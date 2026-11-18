extends GutTest
## M007 Rourke's first job (RourkeJob, pure, with Rackets): offered, taken,
## put off or turned down; who did it learnt; settled four ways; reported
## truthfully or not; what Rourke finds out later; saved.

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new()
	talk = Conversations.new(r)


func _ids(page: Dictionary) -> Array:
	return (page.options as Array).map(func(o: Dictionary) -> String: return o.id)


func test_rourke_offers_it_in_place_of_his_news() -> void:
	var hello := talk.open("rourke")
	assert_has(_ids(hello), "job_offer")
	assert_does_not_have(_ids(hello), "news", "the job takes the place of 'How's business?'")
	var offer := talk.choose("rourke", "job_offer")
	assert_eq(offer.text, JobLines.text("offer"))
	assert_eq(offer.tone, "leaning in, low", "the line's performance tag")
	assert_eq(_ids(offer), ["job_accept", "job_postpone", "job_decline", "bye"])
	assert_eq(r.job.stage, RourkeJob.Stage.OFFERED)


func test_accepting() -> void:
	var trust := r.boss.trust
	talk.choose("rourke", "job_offer")
	var page := talk.choose("rourke", "job_accept")
	assert_eq(page.text, JobLines.text("accepted"))
	assert_eq(r.job.stage, RourkeJob.Stage.ACCEPTED)
	assert_gt(r.boss.trust, trust)
	assert_has(_ids(talk.open("rourke")), "job_report", "now Rourke wants to hear how it goes")
	assert_eq(r.job.objective().where, "hardware", "start with Lindqvist")


func test_putting_it_off() -> void:
	talk.choose("rourke", "job_offer")
	talk.choose("rourke", "job_postpone")
	assert_eq(r.job.stage, RourkeJob.Stage.OFFERED)
	assert_false(r.job.rourke_has_business(r.night), "he does not ask again tonight")
	assert_does_not_have(_ids(talk.open("rourke")), "job_offer")
	r.night += 1
	assert_has(_ids(talk.open("rourke")), "job_offer", "the next night he asks again")
	talk.choose("rourke", "job_offer")
	assert_eq(talk.choose("rourke", "job_postpone").text, JobLines.text("postponed_again"))
	r.night += 1
	talk.choose("rourke", "job_offer")
	assert_eq(talk.choose("rourke", "job_postpone").text, JobLines.text("given_away"), "three times and it goes to somebody else")
	assert_eq(r.job.stage, RourkeJob.Stage.DECLINED)


func test_turning_it_down_disappoints_but_does_not_make_an_enemy() -> void:
	var trust := r.boss.trust
	talk.choose("rourke", "job_offer")
	var page := talk.choose("rourke", "job_decline")
	assert_eq(page.text, JobLines.text("declined"))
	assert_eq(r.job.stage, RourkeJob.Stage.DECLINED)
	assert_eq(r.job.verdict, "disappointed")
	assert_lt(r.boss.trust, trust)
	assert_false(r.boss.ban, "not an enemy")
	assert_ne(r.boss.mood(), "angry")
	assert_has(_ids(talk.open("rourke")), "news", "and back to business as usual")


func test_no_job_when_lefty_is_already_dead() -> void:
	var page := talk.choose("rourke", "job_offer", {"lefty_dead": true})
	assert_eq(page.text, JobLines.text("moot"))
	assert_eq(r.job.stage, RourkeJob.Stage.MOOT)


func test_saved_and_loaded() -> void:
	talk.choose("rourke", "job_offer")
	talk.choose("rourke", "job_accept")
	r.job.learn("culprit")
	var s := Rackets.new()
	s.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(s.job.stage, RourkeJob.Stage.ACCEPTED)
	assert_true(s.job.knows_culprit())
	var old := Rackets.new()
	old.from_dict({"money": 500})
	assert_eq(old.job.stage, RourkeJob.Stage.NOT_OFFERED, "a game saved before M007 starts without it")


# ------------------------------------------------------------------ M007.3 learning and settling it

func _taken() -> void:
	talk.choose("rourke", "job_offer")
	talk.choose("rourke", "job_accept")


func test_lindqvist_and_eddie_tell_what_they_know() -> void:
	assert_does_not_have(_ids(talk.open("lindqvist")), "job_ask", "nothing to ask before the job")
	assert_does_not_have(_ids(talk.open("eddie")), "job_lefty")
	_taken()
	assert_has(_ids(talk.open("lindqvist")), "job_ask")
	assert_does_not_have(_ids(talk.open("eddie")), "job_lefty", "Eddie: only once Danny has a name")
	var told := talk.choose("lindqvist", "job_ask")
	assert_eq(told.text, JobLines.text("lindqvist_tells"))
	assert_true(r.job.knows_culprit())
	assert_does_not_have(_ids(talk.open("lindqvist")), "job_ask", "asked once")
	talk.choose("eddie", "job_lefty")
	assert_true(r.job.learned.has("tip"))


func test_lefty_before_the_job_is_just_lefty() -> void:
	assert_eq(_ids(talk.open("lefty")), ["who", "bye"])
	_taken()
	assert_eq(_ids(talk.open("lefty")), ["who", "bye"], "Danny doesn't know it's him yet")
	r.job.learn("culprit")
	assert_eq(_ids(talk.open("lefty")), ["job_talk", "job_threaten", "job_fight", "bye"])


func test_threats_depend_on_what_is_behind_them() -> void:
	_taken()
	r.job.learn("culprit")
	var j := r.job
	assert_false(j.threat_works({}), "empty hands, healthy: not enough")
	assert_true(j.threat_works({"gun_drawn": true}), "a gun in his face")
	j.learn("tip")
	assert_true(j.threat_works({}), "knowing how he fights, and saying so")
	assert_false(j.threat_works({"danny_worst": BodyCondition.Level.CRITICAL}), "not from a man who can barely stand")
	assert_true(j.threat_works({"gun_drawn": true, "lefty_hurt": true, "danny_worst": BodyCondition.Level.CRITICAL}))
	j.fight_lost_night = 1
	assert_false(j.threat_works({"gun_drawn": true}), "he beat Danny once already")


func test_settled_by_talk_threat_and_fists() -> void:
	for how in ["deal", "backed_down", "beaten"]:
		r = Rackets.new()
		talk = Conversations.new(r)
		_taken()
		r.job.learn("culprit")
		var money := r.money
		r.job.resolve(how, r)
		assert_eq(r.job.stage, RourkeJob.Stage.RESOLVED, how)
		assert_eq(r.money - money, 0 if how == "deal" else RourkeJob.RECOVERABLE, how + ": what Lefty handed over")
		assert_eq(r.job.objective().where, "copper_owl", how + ": tell Rourke")
		assert_eq(talk.open("lefty").text, JobLines.text("lefty_after_" + how), how)
		assert_eq(r.memory.recent("lindqvist", "favour", r.night), 1, how + ": the Swede is grateful")


func test_a_lost_fight_leaves_the_job_open() -> void:
	_taken()
	r.job.learn("culprit")
	var lost := talk.choose("lefty", "job_fight_lost")
	assert_eq(lost.text, JobLines.text("lefty_won"))
	assert_eq(r.job.outcome, "")
	assert_true(r.job.can_confront(), "never stuck")
	assert_false(r.job.lefty_fights(r.night), "not again tonight")
	assert_true(r.job.lefty_fights(r.night + 1), "tomorrow, if he wants")
	assert_eq(talk.open("lefty").text, JobLines.text("lefty_after_lost"))
	assert_does_not_have(_ids(talk.open("lefty")), "job_fight")
	assert_eq(talk.open("lindqvist").text, JobLines.text("lindqvist_waiting"), "Lefty told the Swede")


func test_shooting_lefty() -> void:
	_taken()
	r.job.shot_lefty(r, false)
	r.job.shot_lefty(r, false)
	assert_eq(r.job.attempts.size(), 1, "the first wound is what counts")
	assert_false(r.job.lefty_talks())
	r.job.learn("culprit")
	assert_eq(talk.choose("lefty", "job_talk").text, JobLines.text("lefty_no_talk"))
	r.job.shot_lefty(r, true)
	assert_eq(r.job.outcome, "killed")
	assert_eq(talk.open("lindqvist").text, JobLines.text("lindqvist_killed"))


func test_lefty_shot_dead_before_the_job_is_danny_s() -> void:
	r.job.shot_lefty(r, true)
	assert_eq(r.job.outcome, "", "not Danny's job to settle")
	assert_eq(r.job.offer(r, true), "moot")


func test_returning_the_money_to_lindqvist() -> void:
	_taken()
	r.job.learn("culprit")
	r.job.resolve("beaten", r)
	var opts := _ids(talk.open("lindqvist"))
	assert_has(opts, "job_return")
	var money := r.money
	var page := talk.choose("lindqvist", "job_return")
	assert_eq(page.text, JobLines.text("lindqvist_returned"))
	assert_eq(money - r.money, RourkeJob.RECOVERABLE)
	assert_eq(r.job.money_went, "lindqvist")
	assert_does_not_have(_ids(talk.open("lindqvist")), "job_return", "once")


func test_after_lying_danny_can_still_make_it_true() -> void:
	_taken()
	r.job.learn("culprit")
	r.job.report("job_handled", r)
	assert_eq(r.job.stage, RourkeJob.Stage.REPORTED)
	assert_true(r.job.can_confront(), "before the Swede talks")
	assert_eq(r.job.objective().where, "lefty")
	r.job.resolve("deal", r)
	r.job.end_night(r)
	assert_false(r.rumours.items.any(func(x: Dictionary) -> bool: return x.kind == "job_still"), "nothing for the Swede to complain about")
