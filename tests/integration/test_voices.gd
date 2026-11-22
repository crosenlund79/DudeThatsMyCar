extends "res://tests/support/city_test.gd"
## M006 the people's voices in the game: a recorded greeting the first time
## Danny meets Augie, Rourke and Eddie (never again, even after saving and
## loading), Eddie's sales line the first time he shows his wares, one voice
## at a time, the night stepping back under it, and walking away ending it.

var _save := ""


func before_each() -> void:
	meet_people = true
	await super()


func after_each() -> void:
	super()
	if _save != "" and FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)


class SilentResolver extends AssetResolver:
	func get_audio(_logical: String, _loop: bool = false) -> AudioStream:
		return null


func test_augie_greets_danny_the_first_time_only() -> void:
	await talk_to("copper_owl", "augie")
	assert_eq(main.dialogue.page.voice, ["augie_greeting"])
	assert_eq(main.dialogue.page.text, VoiceLines.text("augie_greeting"), "his words on the page")
	assert_eq(main.voice.current, "augie_greeting", "and in his voice")
	assert_false(main.voice_lines.due("augie_greeting"))
	await wait_physics_frames(60)
	assert_gt(main.soundscape.duck, 0.9, "the band steps back while he talks")
	await answer_with("hello")
	assert_true((main.dialogue.page.options as Array).any(func(o: Dictionary) -> bool: return o.id == "protection"), "then his usual page")
	await press_e()
	assert_eq(main.dialogue.talking, "")
	await wait_physics_frames(30)
	assert_eq(main.voice.current, "", "walking away ends it")
	await wait_physics_frames(60)
	assert_lt(main.soundscape.duck, 0.1, "the band comes back up")
	await talk_to("copper_owl", "augie")
	assert_false(main.dialogue.page.has("voice"), "never twice")
	assert_eq(main.voice.current, "")


func test_eddie_greeting_then_his_sales_line_one_after_the_other() -> void:
	await talk_to("hardware", "eddie")
	assert_eq(main.voice.current, "eddie_greeting")
	await answer_with("hello")
	await answer_with("wares")
	assert_eq(main.dialogue.page.text, VoiceLines.text("eddie_sales"))
	assert_eq(main.voice.current, "eddie_greeting", "he finishes his greeting first")
	assert_eq(main.voice.queue, ["eddie_sales"] as Array[String], "the sales line waits its turn")
	var length: float = main.resolver.get_audio("voice/eddie_greeting").get_length()
	for i in int(length * 60.0) + 30:
		await wait_physics_frames(1)
		assert_true(main.voice.player.playing or main.voice.current == "", "one voice at a time")
		if main.voice.current == "eddie_sales":
			break
	assert_eq(main.voice.current, "eddie_sales", "then the sales line")
	await answer_with("bye")
	assert_eq(main.dialogue.talking, "")
	await talk_to("hardware", "eddie")
	await answer_with("wares")
	assert_eq(main.voice.current, "", "the sales line was said once")


func test_rourke_remembers_meeting_him_across_saves() -> void:
	_save = OS.get_user_data_dir().path_join("test_voices_%d.json" % Time.get_ticks_usec())
	main.save_path = _save
	await talk_to("copper_owl", "rourke")
	assert_eq(main.voice.current, "rourke_greeting", "back after years away")
	assert_string_contains(main.dialogue.page.text, "Look what the wind dragged back into Chicago.")
	await press_e()
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
	assert_null(main.opening)
	await talk_to("copper_owl", "rourke")
	assert_false(main.dialogue.page.has("voice"), "a loaded game remembers they have met")
	assert_string_contains(main.dialogue.page.text, Rackets.dollars(main.rackets.boss.expected), "straight to business")
	main.save_path = ""


func test_a_missing_recording_never_stops_the_talk() -> void:
	main.voice.setup(SilentResolver.new(""), main.voice_lines)
	await talk_to("copper_owl", "augie")
	assert_eq(main.dialogue.page.text, VoiceLines.text("augie_greeting"), "the greeting is still on the page")
	assert_eq(main.voice.current, "", "silently")
	await answer_with("hello")
	assert_eq(main.dialogue.talking, "augie")
	assert_false(main.voice_lines.due("augie_greeting"), "and the meeting still counts")
