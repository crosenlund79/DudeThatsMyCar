extends "res://tests/support/city_test.gd"
## M007 the job's middle in the game, with the normal controls: Lindqvist
## names the man, Eddie knows how he fights, and outside Doyle's Garage Danny
## talks Lefty round, leans on him, puts up his fists (wins, or loses and finds
## another way) or shoots him - each settles it differently, and none of it
## leaves the job stuck.


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func job() -> RourkeJob:
	return main.rackets.job


func lefty() -> Rival:
	return main.rival


## The job taken at Rourke's table (the conversation itself is test_rourkes_job's).
func _taken(knows: bool = true) -> void:
	job().offer(main.rackets, false)
	job().accept(main.rackets)
	if knows:
		job().learn("culprit")


func _ids() -> Array:
	return main._page.get("options", []).map(func(o: Dictionary) -> String: return o.id)


## Walks up to Lefty at his corner and presses E.
func _meet_lefty() -> void:
	walker().place(lefty().body.global_position + Vector2(-32, 0), 0.0)
	await wait_physics_frames(3)
	await press_e()
	assert_eq(main.talking, "lefty")


## Plays the dial: Space in the zone for each check in `plan` that is true.
func _fight(plan: Array) -> void:
	for i in 60:
		if main.fighting:
			break
		await wait_physics_frames(1)
	assert_true(main.fighting, "the fight is on")
	var dial: FightDial = main.hud.fight_dial
	for want in plan:
		while dial.fight.phase != FistFight.Phase.RUNNING and not dial.fight.is_over():
			await wait_physics_frames(1)
		if want:
			while not dial.fight.in_zone() and dial.fight.phase == FistFight.Phase.RUNNING:
				await wait_physics_frames(1)
			main._unhandled_input(_key(CityInput.HANDBRAKE))
		while dial.fight.phase == FistFight.Phase.RUNNING:
			await wait_physics_frames(1)
	for i in 120:
		if not main.fighting:
			break
		await wait_physics_frames(1)


func test_lindqvist_names_him_and_eddie_knows_how_he_fights() -> void:
	_taken(false)
	assert_eq(job().objective().where, "hardware")
	await talk_to("hardware", "lindqvist")
	await answer_with("job_ask")
	assert_true(job().knows_culprit())
	assert_string_contains(main.hud.line_label.text, "Lefty Moran")
	assert_string_contains(main.hud.speaker_label.text, "(glancing at the door, voice down)")
	assert_eq(job().objective().where, "lefty", "the map now points at his corner")
	await press_e()
	await talk_to("hardware", "eddie")
	await answer_with("job_lefty")
	assert_true(job().learned.has("tip"))
	assert_string_contains(main.hud.line_label.text, "Leads with his right")
	await press_e()


func test_talked_round_without_a_shot_or_a_punch() -> void:
	_taken()
	var money: int = main.rackets.money
	await _meet_lefty()
	assert_has(_ids(), "job_talk")
	assert_has(_ids(), "job_threaten")
	assert_has(_ids(), "job_fight")
	await answer_with("job_talk")
	await answer_with("job_money")
	assert_eq(job().outcome, "", "Rourke's money: no chance")
	await press_e()
	await _meet_lefty()
	await answer_with("job_talk")
	await answer_with("job_deal")
	assert_eq(job().outcome, "deal")
	assert_eq(main.rackets.money, money, "he keeps what he took")
	assert_false(lefty().is_hostile(), "no hard feelings")
	assert_eq(job().objective().where, "copper_owl", "back to Rourke")
	await press_e()
	await _meet_lefty()
	assert_string_contains(main.hud.line_label.text, "square")


func test_a_threat_needs_something_behind_it() -> void:
	_taken()
	await _meet_lefty()
	await answer_with("job_threaten")
	assert_eq(job().outcome, "", "hands in his pockets: Lefty calls the bluff")
	assert_string_contains(main.hud.line_label.text, "You don't scare me")
	assert_does_not_have(_ids(), "job_threaten", "not twice in one night")
	await press_e()
	# the next night, with the gun out
	main.rackets.night += 1
	walker().gun.state = Gun.State.READY
	await _meet_lefty()
	var money: int = main.rackets.money
	await answer_with("job_threaten")
	assert_eq(job().outcome, "backed_down")
	assert_eq(main.rackets.money, money + RourkeJob.RECOVERABLE, "twenty bucks to make it go away")
	assert_false(lefty().is_hostile(), "a gun in his face, not a shot")


func test_won_with_his_fists() -> void:
	_taken()
	job().learn("tip")
	var money: int = main.rackets.money
	await _meet_lefty()
	await answer_with("job_fight")
	assert_string_contains(main.hud.line_label.text, "Been waiting")
	await answer_with("bye")  # raises his fists
	await _fight([true, true, true, true, true])
	assert_eq(job().outcome, "beaten")
	assert_eq(main.rackets.money, money + RourkeJob.RECOVERABLE)
	assert_eq(main.talking, "lefty", "Lefty has something to say from the ground")
	assert_string_contains(main.hud.line_label.text, "off my list")
	assert_false(lefty().is_down(), "beaten, not dead")
	assert_false(lefty().is_hostile())
	await press_e()
	await wait_physics_frames(3)
	assert_false(main.fighting)


func test_lost_and_then_another_way() -> void:
	_taken()
	await _meet_lefty()
	await answer_with("job_fight")
	await press_e()  # walking away from the line raises his fists too
	await _fight([false, false, false, false, false])
	assert_eq(job().outcome, "", "still Rourke's problem")
	assert_eq(job().fight_lost_night, main.rackets.night)
	assert_true(walker().condition.level("head") >= BodyCondition.Level.WOUNDED, "a black eye")
	assert_string_contains(main.hud.line_label.text, "Come back when you can stand up")
	await press_e()
	main._unhandled_input(_key(CityInput.STATUS))
	assert_eq(main.hud.status_screen.tint_of("head"), StatusScreen.TINT[BodyCondition.Level.WOUNDED], "on the status screen")
	main._unhandled_input(_key(CityInput.STATUS))
	await _meet_lefty()
	assert_string_contains(main.hud.line_label.text, "How's the jaw")
	assert_does_not_have(_ids(), "job_fight", "not again tonight")
	assert_has(_ids(), "job_talk", "never stuck: there is still talk")
	await answer_with("job_talk")
	await answer_with("job_deal")
	assert_eq(job().outcome, "deal")


func test_the_gun_settles_it_the_hard_way() -> void:
	_taken()
	var body := lefty().body
	body.hit_by_bullet(body.global_position + Vector2(0, 4), Vector2.RIGHT, walker())
	assert_true(job().lefty_shot, "Danny shot him")
	assert_true(lefty().is_hostile(), "the M006 rules: he shoots back")
	assert_eq(job().outcome, "", "wounded is not settled")
	for i in 30:
		if lefty().is_down():
			break
		body.hit_by_bullet(body.global_position + Vector2(0, 4), Vector2.RIGHT, walker())
	assert_true(lefty().is_down())
	assert_eq(job().outcome, "killed")
	assert_has(job().report_options(), "job_truth")
	await talk_to("hardware", "lindqvist")
	assert_string_contains(main.hud.line_label.text, "Morgue")


func test_a_wounded_lefty_will_not_talk_but_can_be_leaned_on() -> void:
	_taken()
	var body := lefty().body
	body.condition.hurt("torso", 45)  # winged in an earlier exchange
	job().shot_lefty(main.rackets, false)
	await _meet_lefty()
	await answer_with("job_talk")
	assert_string_contains(main.hud.line_label.text, "past talking")
	await answer_with("job_threaten")
	assert_eq(job().outcome, "backed_down", "a hurt man folds")
