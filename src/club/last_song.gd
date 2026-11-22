class_name LastSong
extends JobDirector
## M014 (from main): the game side of "After the Last Song" (M012) - once, on a
## night Danny is in the Copper Owl after half past one and has met her, the
## Bird's next song is her last: she steps down to the end of the bar and asks
## him to stay. He can let her be (she waits a while, then lets it be) or go
## to her: a short film, her question, his answer (remembered). What he said is
## kept in Rackets (bird_scene); the lines are Conversations'.

## After this hour (1:30 AM) her next song is her last, if Danny is in the club.
const LAST_SONG := 25 * 60 + 30.0

## "" none tonight; "asking" - her last song over, she asks Danny to stay;
## "film" - the scene playing.
var scene := ""
var _ask_left := 0.0


func id() -> String:
	return "last_song"


## Where she sits after it: the end of the bar.
func seat() -> Vector2:
	return game.locations.at("riverside/place/bird_seat")


func effects() -> Dictionary:
	return {"bird_scene": func(v: Variant, _e: Dictionary) -> void: said(String(v))}  # what he told the Bird


func busy() -> bool:
	return scene != ""


## Every frame (between the routines and the call-outs, as M012 had it): she
## waits for him at the bar; or, the first time the hour and the night are
## right, her song is her last. `enabled`: scene tests switch it off with the
## call-outs.
func update(delta: float, enabled: bool) -> void:
	var bird_show := game.bird_show
	var interiors := game.interiors
	if scene == "asking":
		var b: Walker = bird_show.bird if bird_show != null else null
		if b == null or b.down:
			scene = ""
			return
		var to := seat() - b.global_position
		b.move = to.normalized() * 0.5 if to.length() > 4.0 else Vector2.ZERO
		if to.length() <= 4.0:
			b.aim_point = game.walker.global_position
		_ask_left -= delta
		var away: bool = interiors.current == null or interiors.current.id != "copper_owl"
		if _ask_left <= 0.0 or away:
			scene = ""  # she let it be; she'll sing again tomorrow and ask another night
			game.overhead.hush()
			b.move = Vector2.ZERO
		return
	var r := game.rackets
	var stage := game.stage
	if scene != "" or not enabled or r.bird_scene != "" or game.clock.minute < LAST_SONG:
		return
	if not stage.singing() or game.casualties.is_out("bird") or bird_show == null:
		return
	var player := game.player
	if interiors.current == null or interiors.current.id != "copper_owl" or not player.on_foot():
		return
	if game.voice_lines.due("bird_greeting") or game.dialogue.talking != "" or game.fights.fighting or game.back_rooms.at_a_table() \
			or game.people.since_gunfire() < 30.0 or not player.seat.is_empty():
		return  # they have not met yet, or Danny is busy
	stage.finish()
	game.soundscape.stop_music()
	bird_show.off_stage = true
	scene = "asking"
	_ask_left = 40.0
	game.overhead.say(bird_show.bird, "That's the last one, folks. ...Stay a minute, Mercer?")
	game.hud.show_notice("The last song of the night. The Bird steps down from the bandstand.")


## The Bird off the bandstand, asking him to stay (before the room's own spots).
func spot(at: Vector2) -> Dictionary:
	var bird_show := game.bird_show
	if scene == "asking" and bird_show != null and at.distance_to(bird_show.bird.global_position) < 60.0:
		return {"id": "bird_scene", "prompt": "Stay a minute with the Bird", "pos": bird_show.bird.global_position}
	return {}


func use(_spot: Dictionary) -> void:
	start_film()


## The scene itself, in the game (like the cafe's film): the bars in, the
## camera leaving Danny for the end of the bar, the club's lamps low and the
## room hushed, a few lines - then her question, and his answer.
func start_film() -> void:
	game.dialogue.end()
	scene = "film"
	game.overhead.hush()
	var walker := game.walker
	var camera := game.camera
	var me := walker.global_position
	var her := seat()
	var bird: Walker = game.bird_show.bird
	bird.move = Vector2.ZERO  # at the end of the bar, turned to him
	bird.place(her, (me - her).angle())
	bird.aim_point = me
	var z := camera.zoom.x
	walker.aim_point = her
	var keys := [
		{"t": 0.0, "pos": me, "zoom": z},
		{"t": 3.0, "pos": me.lerp(her, 0.5), "zoom": z * 1.2},
		{"t": 6.5, "pos": her + Vector2(0, 10), "zoom": z * 1.55},
		{"t": 13.0, "pos": her + Vector2(-6, 4), "zoom": z * 1.65},
	]
	var captions := [
		{"t": 0.3, "text": "The band packs up. Somebody starts stacking chairs on the tables."},
		{"t": 3.4, "text": "The Bird sits at the end of the bar with a glass of water dressed up as gin."},
		{"t": 7.4, "text": "\"Every night a man at that corner table decides what I'm worth,\" she says. \"Tonight it was Rourke.\""},
	]
	var cues := [{"t": 0.4, "id": "lamps"}, {"t": 1.0, "id": "hush"}]
	var film := Cinematic.new()
	game.root.add_child(film)
	film.hold = true
	film.start(keys, captions, cues, load(Hud.FONT_PATH))
	film.cue.connect(_on_cue)
	film.held.connect(_on_question)
	film.finished.connect(_end_film)
	game.films.hand_over("bird", film, 2.2)
	walker.move = Vector2.ZERO
	camera.target = film.rig


func _on_cue(cue_id: String) -> void:
	match cue_id:
		"lamps":
			var owl := game.interiors.view_of("copper_owl")
			if owl != null:
				owl.dim(0.55)  # the house lights down after the last number
		"hush":
			game.soundscape.set_duck(true)


## The film has reached her: the question, and his answer (a talk inside the film).
func _on_question() -> void:
	var film := game.films.of("bird") as Cinematic
	film.captions = []  # her words go to the talk below; the film's line and its "skip" make room
	film.caption.text = ""
	film.hint.visible = false
	game.hud.visible = true
	game.player.set_physics_process(true)
	game.dialogue.start("bird_scene")


## What he told her (once ever): remembered by her, and by the save.
func said(what: String) -> void:
	var r := game.rackets
	if r.bird_scene != "":
		return
	r.bird_scene = what
	r.bird_scene_night = r.night
	var kind: String = {"truth": "told_truth", "kind": "kept_quiet", "guard": "held_back"}.get(what, "")
	if kind != "":
		r.memory.remember("bird", kind, r.night)
	game.save()


## A talk ended: her question walked away from is an answer too; the bars slide
## away, the camera comes back.
func talk_ended(who: String) -> void:
	var film := game.films.of("bird") as Cinematic
	if who == "bird_scene" and film != null:
		if game.rackets.bird_scene == "":
			said("silent")  # walked away from her question: that is an answer too
		film.release()  # the bars slide away, the camera comes back


func _end_film() -> void:
	game.films.take_back(game.player.body())
	game.soundscape.set_duck(false)
	var owl := game.interiors.view_of("copper_owl")
	if owl != null:
		owl.dim(0.85)  # after hours: the house lights stay a little low tonight
	scene = ""
	game.save()


## A new night: back at her microphone, the house lights up.
func new_night() -> void:
	if game.bird_show != null:
		game.bird_show.off_stage = false  # M012: back at her microphone
	scene = ""
	var owl := game.interiors.view_of("copper_owl")
	if owl != null:
		owl.dim(1.0)  # the house lights up for a new night
