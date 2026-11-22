extends "res://tests/support/city_test.gd"
## M005 three nights in the Riverside Ward with the normal controls, the way
## a player would: an honest night's work (rye from Sal to Augie, protection
## from Augie and Novak, Rourke paid in full), a greedy one (half of it kept
## back), the game saved and loaded in between, and the third night's
## consequences - while the Copper Owl's singer sings on the same player,
## never restarted, and the deals sound as they happen.

var _save := ""


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


func _deal_money() -> int:
	return main.rackets.money + main.rackets.town.total_cash() + main.rackets.boss.purse


func _sleep() -> void:
	await talk_to("home", "bed")
	await answer_with("sleep")
	await wait_physics_frames(5)


func _collect(plan: String, who: String) -> void:
	await talk_to(plan, who)
	await answer_with("protection")
	await answer_with("ask")
	await press_e()


func test_three_nights_in_the_ward() -> void:
	var music: AudioStreamPlayer = main.soundscape.music
	var r: Rackets = main.rackets
	# --- night 1: an honest night's work
	assert_eq(r.night, 1)
	var before := _deal_money()
	await talk_to("barber_shop", "sal")
	await answer_with("buy_all")
	await answer_with("bye")
	assert_gt(r.bottles, 0)
	assert_eq(_deal_money(), before, "buying moves money, it makes none")
	assert_has(main.soundscape.played, "places/bottles")
	await talk_to("copper_owl", "augie")
	await answer_with("sell")
	assert_eq(r.bottles, 0)
	assert_eq(_deal_money(), before, "selling moves money, it makes none")
	assert_has(main.soundscape.played, "places/register", "Augie's till")
	await press_e()
	await _collect("copper_owl", "augie")
	await _collect("grocery", "novak")
	var owed: int = r.held
	assert_eq(owed, r.club().protection + r.town.get_business("grocery").protection, "both paid")
	var trust: int = r.boss.trust
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	# he watched the rye go over Augie's bar and wants his tenth of it too:
	# the honest answer makes up the difference from Danny's pocket
	assert_gt(r.boss.expected + r.boss.rye_end(), r.held)
	await answer_with("top_up")
	assert_true(r.boss.settled)
	assert_eq(r.held, 0)
	assert_eq(r.boss.arrears, 0)
	assert_gte(r.boss.trust, trust, "a straight night")
	await press_e()
	var club_cash_before_day: int = r.club().cash
	await _sleep()
	assert_eq(r.night, 2)
	assert_ne(r.club().cash, club_cash_before_day, "the ward lived through the day while Danny slept")
	# --- night 2: keeping half of it back
	await _collect("copper_owl", "augie")
	await _collect("grocery", "novak")
	trust = r.boss.trust
	await talk_to("copper_owl", "rourke")
	await answer_with("envelope")
	await answer_with("skim")
	assert_gt(r.skimmed, 0, "Danny kept some back")
	assert_gt(r.boss.arrears, 0, "Rourke knows he is owed")
	assert_lt(r.boss.trust, trust, "and trusts him less")
	await press_e()
	# --- save, quit and load mid-night: everything is still there, no opening
	_save = OS.get_user_data_dir().path_join("test_ears_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	main.save_game()
	var kept := {"money": r.money, "night": r.night, "arrears": r.boss.arrears, "trust": r.boss.trust,
		"skimmed": r.skimmed, "novak": r.memory.attitude("novak", r.night), "club_cash": r.club().cash}
	remove_child(main)
	main.free()
	main = MAIN.instantiate()
	main.command_source = _source
	main.callouts_enabled = callouts  # M012: as in before_each
	main.save_path = _save
	main.settings_path = ""
	add_child_autofree(main)
	main.street.clear()
	await wait_physics_frames(3)
	r = main.rackets
	assert_null(main.films.of("opening"), "a loaded game goes straight on")
	assert_eq(r.money, kept.money)
	assert_eq(r.night, kept.night)
	assert_eq(r.boss.arrears, kept.arrears)
	assert_eq(r.boss.trust, kept.trust)
	assert_eq(r.skimmed, kept.skimmed)
	assert_eq(r.club().cash, kept.club_cash)
	assert_eq(r.memory.attitude("novak", r.night), kept.novak, "Novak remembers")
	music = main.soundscape.music
	await _sleep()
	# --- night 3: the consequences
	assert_eq(r.night, 3)
	assert_gt(r.boss.expected, r.boss.believed_due(r.club()), "tonight he wants what he is owed on top")
	assert_ne(r.boss.mood(), "warm")
	await talk_to("copper_owl", "rourke")
	assert_string_contains(main.dialogue.page.text, Rackets.dollars(r.boss.expected), "and says so")
	await press_e()
	assert_same(main.soundscape.music, music, "one player")
	assert_true(music.playing)
	assert_eq(main.soundscape.music_starts, 1, "the singer was never restarted")
	main.save_path = ""
