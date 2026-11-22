extends "res://tests/support/city_test.gd"
## M003 the henchman's night: he wakes at home in the evening with the clock
## on screen, time runs, late at night he is told to go home (never forced),
## and sleeping in his bed brings the next evening with his money, bottles
## and rounds, a fresh night of deals, and the streets as they were.


func test_the_night_begins_at_home_in_the_evening() -> void:
	assert_eq(main.interiors.current.id, "home")
	assert_eq(main.hud.place_label.text, "Your Flat")
	assert_string_contains(main.hud.clock_label.text, "NIGHT 1")
	assert_string_contains(main.hud.clock_label.text, "7:30 PM")
	assert_true(main.hud.clock_panel.visible)
	assert_false(main.hud.home_label.visible)
	var before: float = main.clock.minute
	await wait_physics_frames(120)
	assert_gt(main.clock.minute, before, "time runs")


func test_late_at_night_he_is_told_to_go_home_but_not_forced() -> void:
	main.clock.set_time(main.night_rules.home_minute)
	await wait_process_frames(3)
	assert_true(main.hud.home_label.visible, "GET HOME TO BED under the clock")
	assert_string_contains(main.hud.notice_label.text, "home")
	main.clock.set_time(main.night_rules.dawn_minute)
	await wait_process_frames(3)
	assert_string_contains(main.hud.notice_label.text, "Dawn")
	await at_the_streetcar_stop()
	await hold(Vector2(1, 0), 30)
	assert_gt(walker().global_position.x, STREETCAR_STOP.x + 20.0, "he still walks the streets")
	assert_eq(main.rackets.night, 1, "nobody sleeps for him")


func test_the_bed_offers_sleep_and_he_can_say_not_yet() -> void:
	await talk_to("home", "bed")
	assert_eq(main.dialogue.talking, "bed")
	assert_string_contains(main.dialogue.page.text, "young", "it's early yet")
	await answer_with("bye")
	assert_eq(main.rackets.night, 1)


func test_sleeping_brings_the_next_evening_and_keeps_what_he_carries() -> void:
	# a night's work: rye from Sal, protection from Novak, some shots fired
	main.rackets.buy_bottles(4)
	main.rackets.collect("grocery", false)
	walker().gun.spare = 3
	var money: int = main.rackets.money
	# the night goes on: a car moved, the copper on the hunt, the clock late
	var c := roadster()
	var home_spot: Vector2 = c.global_position
	await park(c, Vector2(1000, 1500), 0.0)
	main.officer.hear_gunshot(main.officer.body.global_position, 500.0)
	main.clock.set_time(main.night_rules.home_minute + 30)
	await wait_physics_frames(2)
	assert_true(main.officer.brain.is_hunting())
	await talk_to("home", "bed")
	assert_string_contains(main.dialogue.page.text, "turn in")
	await answer_with("sleep")
	assert_eq(main.dialogue.talking, "")
	assert_eq(main.rackets.night, 2, "the next night")
	assert_eq(main.clock.text(), "7:30 PM", "in the evening")
	assert_eq(main.rackets.money, money, "money kept")
	assert_eq(main.rackets.bottles, 4, "bottles kept")
	assert_eq(walker().gun.spare, 3, "rounds kept")
	assert_false(main.rackets.has_paid("grocery"), "protection is due again")
	assert_gt(main.rackets.barber_stock(), 0, "Sal's man brought more rye in the day")
	assert_true(c.global_position.distance_to(home_spot) < 1.0, "the roadster is back at its curb")
	assert_eq(main.officer.brain.state, OfficerBrain.State.PATROL, "the copper is back on his round")
	assert_eq(main.interiors.current.id, "home", "waking at home")
	assert_true(main.hud.wake_screen.visible, "a moment of black with the night's title")
	await wait_process_frames(10)
	assert_string_contains(main.hud.clock_label.text, "NIGHT 2")
	assert_false(main.hud.home_label.visible)
