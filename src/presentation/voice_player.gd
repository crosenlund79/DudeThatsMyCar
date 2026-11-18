class_name VoicePlayer
extends Node
## Plays the people's recorded lines (VoiceLines) one at a time on the Voice
## bus: a line never overlaps another, lines asked for together are said one
## after the other, and walking away ends the talk (the voice fades out in a
## moment). While someone speaks the soundscape steps back (the composition
## root reads `speaking()`). The words are on the dialogue page being shown
## (Conversations writes a voiced page as the line's transcript). A missing
## recording is skipped without a sound; the moment still counts.

signal line_started(id: String)
signal line_finished(id: String)

const FADE := 0.25

var lines: VoiceLines
var player: AudioStreamPlayer
## The line being said ("" when silent), seconds into it, and those waiting.
var current := ""
var time := 0.0
var queue: Array[String] = []
var _resolver: AssetResolver
var _fading := false


func setup(resolver: AssetResolver, p_lines: VoiceLines) -> void:
	name = "VoicePlayer"
	_resolver = resolver
	lines = p_lines
	player = AudioStreamPlayer.new()
	player.bus = "Voice" if AudioServer.get_bus_index("Voice") >= 0 else "Master"
	add_child(player)


func speaking() -> bool:
	return current != ""


## Says the lines that are due, in order, after whatever is being said now.
## Returns the ids that will be said.
func say(ids: Array) -> Array[String]:
	var out: Array[String] = []
	for id in ids:
		if lines.due(id) and not queue.has(id) and current != id:
			out.append(id)
			queue.append(id)
			lines.mark(id)  # heard from the moment it is due: never twice
	if current == "" and not queue.is_empty():
		_next()
	return out


## The talk is over: the voice fades out at once and nothing more is said.
func stop() -> void:
	queue.clear()
	if current == "":
		return
	_fading = true
	var t := create_tween()
	t.tween_property(player, "volume_db", -60.0, FADE)
	t.tween_callback(_finish)


func _next() -> void:
	while not queue.is_empty():
		var id: String = queue.pop_front()
		var logical := VoiceLines.logical(id)
		if not _resolver.has_audio_override(logical) and AssetResolver.audio_fallback_path(logical) == "":
			continue  # no recording at all
		var stream := _resolver.get_audio(logical)
		if stream == null:
			continue  # a missing recording: the talk goes on without it
		current = id
		time = 0.0
		_fading = false
		player.stream = stream
		player.volume_db = float(VoiceLines.LINES[id].gain_db)
		player.play()
		line_started.emit(id)
		return


func _process(delta: float) -> void:
	if current == "":
		return
	var pos := player.get_playback_position() if player.playing else 0.0
	time = pos if pos > time else time + delta
	if not _fading and time >= player.stream.get_length() + 0.15:
		_finish()


func _finish() -> void:
	var done := current
	player.stop()
	current = ""
	_fading = false
	if done != "":
		line_finished.emit(done)
	_next()
