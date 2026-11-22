extends "res://tests/support/city_test.gd"
## M011 the Copper Owl's back rooms as Danny hears them, in the game: every
## new sound resolves to its packaged template (or an override in custom/,
## falling back when none is there), the loops loop; the back rooms' bed on
## one player that never restarts - up inside the card room and the gaming
## room, gone in the club and outside, where the band is full or muffled as
## before; the room's own sounds now and then, only in the back rooms; speech
## ducks them; the wheel's and the machines' sounds in their order, the reels
## on one loop that is never doubled and stops with the last reel. (The
## headless run has no sound card: levels, routing and continuity, not how it
## sounds - see the listening checks in the M011 checklist.)

const SOUNDS := ["ambience/gaming_room", "gaming/laugh", "gaming/chips_stack", "gaming/shuffle", "gaming/glass", "gaming/chair",
	"roulette/spin", "roulette/ball_drop", "roulette/ball_rest", "roulette/chips", "roulette/cue", "roulette/win", "roulette/lose",
	"slots/lever", "slots/reels", "slots/stop", "slots/coin", "slots/bell", "poker/shuffle", "poker/pot", "poker/reveal"]


func after_each() -> void:
	super()
	AudioSettings.new("").apply()


func sound() -> Soundscape:
	return main.soundscape


func _stand(p: Vector2, frames: int = 90) -> void:
	walker().place(p, 0.0)
	main.camera.snap_to(walker())
	await wait_physics_frames(frames)


func test_every_new_sound_resolves_and_loops_as_catalogued() -> void:
	for logical in SOUNDS:
		assert_true(AssetCatalog.AUDIO.has(logical), "%s is in the catalogue" % logical)
		var loop: bool = AssetCatalog.AUDIO[logical].loop
		var s: AudioStream = main.resolver.get_audio(logical, loop)
		assert_not_null(s, "%s resolves to its template" % logical)
		assert_false(main.resolver.has_audio_override(logical), "no override in custom/: the template plays")
		assert_true(FileAccess.file_exists(AssetResolver.audio_fallback_path(logical)), "%s's template is packaged" % logical)
		if loop:
			assert_true((s as AudioStreamOggVorbis).loop, "%s loops" % logical)
		assert_string_contains(main.resolver.audio_override_path(logical, "ogg"), logical, "its override path names it")
	for logical in SOUNDS:
		assert_lt((main.resolver.get_audio(logical) as AudioStream).get_length(), 30.0, "%s is short" % logical)


func test_the_back_rooms_bed_rises_inside_and_never_restarts() -> void:
	assert_eq(sound().gaming_starts, 1, "started once")
	await _stand(Vector2(2290, 600))  # outside on Marlowe Avenue
	assert_eq(sound().level.gaming_db, SoundscapeMix.SILENT_DB, "not in the street")
	await _stand(Vector2(2290, 330))  # in the club
	assert_eq(sound().level.gaming_db, SoundscapeMix.SILENT_DB, "not in the club")
	assert_gt(sound().level.music_db, -6.0, "the band full in the club")
	await _stand(RiversideInteriors.TABLE + Vector2(0, 54), 180)  # the card room
	assert_almost_eq(sound().level.gaming_db, SoundscapeMix.GAMING_DB, 0.5, "the back room's bed up")
	assert_lt(sound().level.music_db, sound().level.gaming_db, "the band behind the wall")
	assert_lte(Soundscape.cutoff_of(Soundscape.BUS_CLUB_MUSIC), SoundscapeMix.OTHER_ROOM_CUTOFF + 1.0, "muffled")
	await _stand(RiversideInteriors.ROULETTE_SPOT)  # the gaming room
	assert_almost_eq(sound().level.gaming_db, SoundscapeMix.GAMING_DB, 0.5)
	var bed_player := sound().gaming_bed
	assert_true(bed_player.playing)
	await _stand(Vector2(2290, 330))  # back in the club
	assert_eq(sound().level.gaming_db, SoundscapeMix.SILENT_DB, "gone again in the club")
	assert_gt(sound().level.music_db, -6.0, "and the band full again")
	assert_eq(sound().gaming_starts, 1, "never restarted")
	assert_eq(sound().gaming_bed, bed_player)
	assert_true(bed_player.playing, "still the same player, playing on")


func test_the_rooms_own_sounds_only_in_the_back_rooms() -> void:
	await _stand(Vector2(2290, 330), 60 * 25)  # the club, 25 seconds
	assert_eq(sound().room_played.size(), 0, "nothing of the back rooms in the club")
	await _stand(RiversideInteriors.TABLE + Vector2(0, 54), 60 * 25)
	assert_gte(sound().room_played.size(), 2, "now and then in the card room (%d)" % sound().room_played.size())
	for s in sound().room_played:
		assert_true(s in Soundscape.ROOM_EVENTS.back_room)
	assert_lte(sound().room_played.size(), 10, "sparse, not one loud loop")


func test_a_voice_ducks_the_back_room() -> void:
	await _stand(RiversideInteriors.ROULETTE_SPOT)
	var normal := sound().gaming_bed.volume_db
	sound().set_duck(true)  # a voice over the night (the game sets the same step back while someone speaks)
	await wait_physics_frames(60)
	assert_lt(sound().gaming_bed.volume_db, normal - 5.0, "steps back under a voice")
	sound().set_duck(false)
	await wait_physics_frames(90)
	assert_almost_eq(sound().gaming_bed.volume_db, normal, 1.0, "and comes back")


func test_the_wheels_sounds_in_order() -> void:
	main.rackets.money = 500
	walker().place(RiversideInteriors.ROULETTE_SPOT, -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	# M013: Leo runs the wheel - wait for a fresh round, put a chip down, let it run
	for i in 3000:
		if main.back_rooms.wheel.phase != RouletteTable.Phase.OPEN:
			break
		await wait_physics_frames(1)
	for i in 3000:
		if main.back_rooms.wheel.phase == RouletteTable.Phase.OPEN:
			break
		await wait_physics_frames(1)
	var heard := []
	sound().sound_played.connect(func(l: String) -> void: heard.append(l))
	main.back_rooms.bet("red", 25)
	for i in 3000:
		await wait_physics_frames(1)
		if main.back_rooms.wheel.phase == RouletteTable.Phase.RESULT:
			break
	await wait_physics_frames(2)
	var order := heard.filter(func(l: String) -> bool: return l.begins_with("roulette/"))
	var no_bells := order.filter(func(l: String) -> bool: return l != "roulette/cue")
	assert_eq(no_bells.slice(0, 4), ["roulette/chips", "roulette/spin", "roulette/ball_drop", "roulette/ball_rest"])
	assert_lt(order.find("roulette/spin"), order.rfind("roulette/cue"), "the croupier's bell at the call")
	assert_lt(order.rfind("roulette/cue"), order.find("roulette/ball_drop"), "before the ball drops")
	assert_true(("roulette/win" in order) != ("roulette/lose" in order), "won or lost, not both")
	assert_eq(order.count("roulette/ball_rest"), 1, "the ball comes to rest once")
	main.back_rooms.leave_roulette()


func test_the_machines_sounds_and_one_reels_loop() -> void:
	main.rackets.money = 500
	walker().place(RiversideInteriors.SLOTS[0] + Vector2(0, 32), -PI / 2)
	main.camera.snap_to(walker())
	await wait_physics_frames(3)
	await press_e()
	var heard := []
	sound().sound_played.connect(func(l: String) -> void: heard.append(l))
	assert_true(main.hud.slot_view.is_open(), "at the Owl")
	main.back_rooms.pull()
	await wait_physics_frames(30)
	assert_true(sound().loop_playing("reels"), "the reels running")
	assert_false(sound().start_loop("reels", "slots/reels"), "started again it is not doubled or restarted")
	for i in 400:
		await wait_physics_frames(1)
		if main.hud.slot_view.phase == "paid":
			break
	await wait_physics_frames(2)
	assert_false(sound().loop_playing("reels"), "quiet when the last reel stops")
	assert_eq(heard.count("slots/lever"), 1)
	assert_eq(heard.count("slots/reels"), 1, "one loop")
	assert_eq(heard.count("slots/stop"), 3, "a clunk for each reel")
	var m: SlotMachine = main.back_rooms.slot_machines[0]
	await wait_physics_frames(150)
	assert_eq(heard.count("slots/coin"), mini(m.win / m.rules.coin, 24), "a coin a coin")
	# stepping away mid-pull stops the reels' sound too
	main.back_rooms.pull()
	await wait_physics_frames(30)
	main.back_rooms.leave_slot()
	assert_false(sound().loop_playing("reels"))
