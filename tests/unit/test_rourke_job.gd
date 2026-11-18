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
