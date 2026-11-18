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


# ------------------------------------------------------------------ M007.4 telling Rourke, and what he finds out

func _settled(how: String, purse: int = 5000) -> void:
	_taken()
	r.job.learn("culprit")
	r.job.resolve(how, r)
	r.boss.purse = purse


## Nights pass (each one's talk goes one step further along the links).
func _nights(n: int) -> void:
	for i in n:
		r.end_night()


func test_rourke_takes_each_way_differently() -> void:
	var seen := {}
	for how in ["deal", "backed_down", "beaten", "killed"]:
		r = Rackets.new()
		talk = Conversations.new(r)
		_settled(how)
		var trust := r.boss.trust
		var patience := r.boss.patience
		var opts := _ids(talk.choose("rourke", "job_report"))
		var claim := "job_truth_hand" if opts.has("job_truth_hand") else "job_truth"
		var page := talk.choose("rourke", claim)
		assert_string_contains(page.text, JobLines.text("report_" + how), how)
		seen[how] = r.job.verdict
		assert_eq(r.job.stage, RourkeJob.Stage.REPORTED, how)
		assert_true(r.job.success, how)
		assert_false(r.boss.ban, how + ": never an enemy for using his judgement")
		match how:
			"deal":
				assert_eq(r.boss.trust, trust + 3)
			"backed_down", "beaten":
				assert_eq(r.boss.trust, trust + 6 + 2, how + ": and he brought the money")
			"killed":
				assert_eq(r.boss.patience, patience - 1, "a dead North Side man brings more")
		assert_eq(r.job.objective().where, "", how + ": done")
	assert_eq(seen, {"deal": "satisfied", "backed_down": "pleased", "beaten": "pleased", "killed": "uneasy"})


func test_the_reward_comes_out_of_his_purse_or_the_next_envelope() -> void:
	_settled("deal", 600)
	var money := r.money
	var out := r.job.report("job_truth", r)
	assert_eq(out.reward, 600, "what his purse holds now")
	assert_eq(r.money - money, 600)
	assert_eq(r.boss.purse, 0)
	assert_eq(r.job.reward_owed, RourkeJob.REWARD - 600)
	assert_has(out.lines, "report_reward_later")
	r.held = 5000
	r.money += 5000
	var paid := r.pay_boss(5000)
	assert_eq(paid.job_reward, RourkeJob.REWARD - 600, "out of the next envelope")
	assert_eq(r.job.reward_owed, 0)


func test_the_reward_comes_off_a_debt_first() -> void:
	_settled("beaten", 0)
	r.boss.arrears = 700
	var out := r.job.report("job_truth", r)
	assert_eq(out.reward, 0)
	assert_eq(r.boss.arrears, 0, "seven dollars off the slate")
	assert_eq(r.job.reward_owed, RourkeJob.REWARD - 700)
	assert_has(out.lines, "report_reward_debt")


func test_keeping_lefty_s_money_is_found_out() -> void:
	_settled("beaten")
	var page := talk.choose("rourke", "job_truth_keep")
	assert_string_contains(page.text, JobLines.text("report_beaten"))
	assert_true(r.job.hid_money)
	var trust := r.boss.trust
	_nights(2)
	assert_eq(r.job.rourke_news, "", "Lefty's bragging hasn't reached him yet")
	_nights(1)
	assert_eq(r.job.rourke_news, "found_money", "Lefty -> Eddie -> Augie -> Rourke")
	assert_eq(r.job.verdict, "lied_to")
	assert_lt(r.boss.trust, trust)
	assert_gte(r.boss.arrears, RourkeJob.RECOVERABLE, "he wants his twenty")
	var hello := talk.open("rourke")
	assert_eq(hello.text, JobLines.text("found_money"), "he says so the first time Danny sits down")
	assert_eq(r.job.rourke_news, "", "once")


func test_saying_it_is_handled_when_it_is_not() -> void:
	_taken()
	r.job.learn("culprit")
	r.boss.purse = 5000
	var page := talk.choose("rourke", "job_handled")
	assert_string_contains(page.text, JobLines.text("report_handled"))
	assert_eq(r.job.objective().where, "lefty", "the map knows better")
	_nights(4)  # the Swede pays again; Lindqvist -> Eddie -> Augie -> Rourke
	assert_eq(r.job.rourke_news, "found_unresolved")
	assert_eq(r.job.stage, RourkeJob.Stage.ACCEPTED, "he still wants it done")
	assert_false(r.job.success)
	assert_gte(r.boss.arrears, RourkeJob.REWARD, "and his money back")
	assert_eq(r.memory.recent("rourke", "lie", r.night, 4), 1)
	assert_true(r.job.can_confront(), "and Danny can still do it")


func test_giving_the_swede_his_money_back_is_told_to_rourke() -> void:
	_settled("backed_down")
	talk.choose("lindqvist", "job_return")
	var out := r.job.report("job_truth", r)
	assert_has(out.lines, "report_returned")
	assert_false(r.job.hid_money, "nothing hidden")
	_nights(4)
	assert_eq(r.job.rourke_news, "", "nothing to find out")
	assert_eq(r.memory.recent("lindqvist", "favour", r.night, 5), 2, "Lefty gone, and his money back")


func test_the_ward_talks_about_it() -> void:
	_settled("beaten")
	_nights(2)
	assert_string_contains(talk.choose("augie", "news").text, "bare hands", "Augie heard by the second night")
	assert_gt(r.memory.recent("augie", "heard_threat", r.night, 3), 0)


func test_saved_with_the_reward_owed() -> void:
	_settled("deal", 0)
	r.job.report("job_truth", r)
	var copy := Rackets.new()
	copy.from_dict(JSON.parse_string(JSON.stringify(r.to_dict())))
	assert_eq(copy.job.reward_owed, RourkeJob.REWARD)
	assert_eq(copy.job.verdict, "satisfied")
	assert_eq(copy.job.stage, RourkeJob.Stage.REPORTED)
