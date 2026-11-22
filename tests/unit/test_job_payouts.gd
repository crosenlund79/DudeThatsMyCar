extends GutTest
## M014: every authored job pays once - and a save written after it paid,
## loaded back (through the save format), never pays it again. Rourke's
## Lindqvist job, the cafe, Freight Doesn't Walk, Dutch's crate and the
## Bijou's reel, through their own rules (the money moved is checked to the cent).

var r: Rackets
var talk: Conversations


func before_each() -> void:
	r = Rackets.new(load("res://src/economy/default_economy.tres"))
	r.money = 5000
	talk = Conversations.new(r)


## The books written to a save file and read back as the game would (migrated, checked).
func _reloaded(from: Rackets) -> Rackets:
	var data: Dictionary = SaveSchema.validate(SaveSchema.migrate(JSON.parse_string(JSON.stringify(
		{"version": SaveSchema.VERSION, "rackets": from.to_dict()})))).data
	var copy := Rackets.new(load("res://src/economy/default_economy.tres"))
	copy.from_dict(data.rackets)
	return copy


func test_the_cafe_pays_once() -> void:
	var c := r.cafe
	c.offer()
	assert_true(c.accept())
	assert_true(c.plant(1, 23 * 60.0, false))
	assert_true(c.blast(1, 23 * 60.0 + CafeJob.FUSE))
	assert_eq(c.report(), CafeJob.REWARD)
	assert_eq(c.report(), 0)
	assert_eq(_reloaded(r).cafe.report(), 0, "not again after a save")


func test_the_freight_fee_once() -> void:
	var f := r.freight
	f.offer(r.night, 21 * 60.0)
	assert_true(f.accept())
	f.learn("docked")
	assert_true(f.talk_leon_round())
	assert_true(f.settle(r, "squared"))
	var money := r.money
	assert_eq(f.collect_fee(r), FreightJob.FEE)
	assert_eq(r.money, money + FreightJob.FEE)
	assert_eq(f.collect_fee(r), 0)
	var copy := _reloaded(r)
	var before := copy.money
	assert_eq(copy.freight.collect_fee(copy), 0, "not again after a save")
	assert_eq(copy.money, before)


func test_dutchs_crate_once() -> void:
	var o := r.opportunities
	assert_true(o.take_crate())
	assert_true(o.load_crate())
	var money := r.money
	assert_eq(r.deliver_crate(), Opportunities.CRATE_PAY)
	assert_eq(r.money - money, Opportunities.CRATE_PAY)
	assert_eq(r.deliver_crate(), 0)
	var copy := _reloaded(r)
	assert_eq(copy.deliver_crate(), 0, "not again after a save")


func test_the_bijous_reel_once() -> void:
	var o := r.opportunities
	o.take_reel()
	assert_true(o.find_reel())
	assert_eq(r.return_reel(), Opportunities.REEL_PAY)
	assert_eq(r.return_reel(), 0)
	assert_eq(_reloaded(r).return_reel(), 0, "not again after a save")


## Rourke's reward through the game's own path - his page: the report is on
## it while the job is settled and gone once it is told (RourkeJob.report has
## no guard of its own against a second call; the page is the guard - noted in
## docs/BACKLOG.md).
func test_rourkes_reward_once() -> void:
	talk.choose("rourke", "job_offer")
	talk.choose("rourke", "job_accept")
	r.job.learn("culprit")
	r.job.resolve("deal", r)
	r.boss.purse = 5000
	var ids := func(page: Dictionary) -> Array: return (page.options as Array).map(func(o: Dictionary) -> String: return o.id)
	assert_true(ids.call(talk.open("rourke")).has("job_report"), "the job on his page")
	assert_true(ids.call(talk.choose("rourke", "job_report")).has("job_truth"), "and what Danny can tell him")
	var money := r.money
	talk.choose("rourke", "job_truth")
	assert_eq(r.money - money, RourkeJob.REWARD, "paid")
	assert_eq(r.job.reward_owed, 0)
	for who in [r, _reloaded(r)]:
		assert_false(ids.call(Conversations.new(who).open("rourke")).has("job_report"), "no report once told")
	var copy := _reloaded(r)
	assert_eq(copy.job.stage, RourkeJob.Stage.REPORTED)
	assert_eq(copy.job.reward_owed, 0, "nothing owed after a save")
