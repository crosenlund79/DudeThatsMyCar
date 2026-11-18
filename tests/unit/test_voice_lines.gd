extends GutTest
## M006 the people's recorded lines (VoiceLines, pure): the user's recordings
## shipped unaltered, transcripts that fit them, first-meeting lines said
## once and remembered in the save, the Bird's complaint every time.

const ORIGINALS := {
	"bird_interrupted": "The Bird Singer - Interrupted on stage.mp3",
	"rourke_greeting": "Rourke The Boss - Greeting when first meeting.mp3",
	"bird_greeting": "The Bird Singer - Greeting when first meeting.mp3",
	"augie_greeting": "Augie Bartender - Greeting when first meeting.mp3",
	"eddie_greeting": "Eddie Gun Dealer - Greeting when first meeting.mp3",
	"eddie_sales": "Eddie Gun Dealer - Greeting when accessing his sales.mp3",
}


func test_the_recordings_ship_byte_for_byte() -> void:
	for id in ORIGINALS:
		var shipped := "res://assets/audio/voice/%s.mp3" % id
		var original: String = "res://assets/audio/_inbox/" + ORIGINALS[id]
		assert_true(FileAccess.file_exists(original), "the original is in the inbox: " + id)
		assert_eq(FileAccess.get_sha256(shipped), FileAccess.get_sha256(original), "unaltered: " + id)
		assert_eq(AssetResolver.audio_fallback_path(VoiceLines.logical(id)), shipped)
		assert_true(AssetCatalog.AUDIO.has(VoiceLines.logical(id)), "catalogued: " + id)


func test_the_subtitles_fit_the_recordings() -> void:
	var r := AssetResolver.new(OS.get_user_data_dir().path_join("no_overrides"))
	for id in VoiceLines.LINES:
		var length := r.get_audio(VoiceLines.logical(id)).get_length()
		var prev := 0.0
		for c in VoiceLines.LINES[id].cues:
			assert_gte(float(c[0]), prev, "%s: in order" % id)
			assert_gt(float(c[1]), float(c[0]))
			assert_lte(float(c[1]), length + 0.1, "%s: inside the recording (%.2f s)" % [id, length])
			prev = c[1]
		assert_lt(absf(float(VoiceLines.LINES[id].gain_db)), 3.0, "only evened out, never pushed")
	assert_eq(VoiceLines.text("rourke_greeting").begins_with("Well, well! Danny Mercer! Look what the wind dragged back"), true)
	assert_eq(VoiceLines.cue_at("eddie_sales", 1.0), "You want something that'll make a noise, or something that'll finish an argument?")
	assert_eq(VoiceLines.cue_at("bird_interrupted", 3.0), "", "a breath between sentences")


func test_first_meetings_once_complaints_every_time() -> void:
	var v := VoiceLines.new()
	assert_true(v.due("augie_greeting"))
	v.mark("augie_greeting")
	assert_false(v.due("augie_greeting"), "said once")
	assert_true(v.due("bird_interrupted"))
	v.mark("bird_interrupted")
	assert_true(v.due("bird_interrupted"), "she complains every time")
	assert_false(v.due("nobody_greeting"), "no such line")


func test_heard_lines_are_saved() -> void:
	var v := VoiceLines.new()
	v.mark("rourke_greeting")
	v.mark("eddie_sales")
	var w := VoiceLines.new()
	w.from_dict(JSON.parse_string(JSON.stringify(v.to_dict())))
	assert_false(w.due("rourke_greeting"))
	assert_false(w.due("eddie_sales"))
	assert_true(w.due("augie_greeting"))
	var old := VoiceLines.new()
	old.assume_old_acquaintances()
	assert_false(old.due("augie_greeting"), "an old game: Danny knows Augie already")
	assert_true(old.due("bird_greeting"), "but the Bird is new")
