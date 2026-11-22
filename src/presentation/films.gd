class_name Films
extends RefCounted
## M014 (from main): the short films in the game - the opening narration
## (M005), the cafe's blast (M010) and the Bird's last song (M012). One plays
## at a time; while it does the HUD and the place markers are hidden, Danny's
## controls wait and the camera follows the film's rig; when it is over (or
## skipped) all of that is handed back. What a film shows, and what happens
## around it, stays with the part of the game that plays it.

var game: Game
## The film playing (an Opening or a Cinematic), or null; and which it is:
## "opening", "cafe" or "bird".
var current: Node = null
var kind := ""
var _follow_rate := 7.0


func _init(p_game: Game) -> void:
	game = p_game


## The film of that kind if it is the one playing (else null).
func of(p_kind: String) -> Node:
	return current if kind == p_kind and current != null else null


func playing() -> bool:
	return current != null


## The screen and the camera go to `film` (already started and in the tree):
## no HUD, no markers, no controls; the camera follows at `follow_rate` (the
## caller points it at the film's rig).
func hand_over(p_kind: String, film: Node, follow_rate: float) -> void:
	current = film
	kind = p_kind
	game.hud.visible = false
	game.markers.visible = false
	game.player.set_physics_process(false)
	_follow_rate = game.camera.follow_rate
	game.camera.follow_rate = follow_rate


## The film is over: the screen, the controls and the camera back to `target`
## (Danny, or his car); the film is freed.
func take_back(target: Node2D) -> void:
	game.hud.visible = true
	game.markers.visible = true
	game.player.set_physics_process(true)
	var camera := game.camera
	camera.target = target
	camera.follow_rate = _follow_rate
	camera.zoom_override = 0.0
	if current != null:
		current.queue_free()
	current = null
	kind = ""


## A key or a click while a film plays: Esc, E, Space or a click skips it (and
## Enter the opening). The Bird's film is not skipped while she is talking to
## him (that is the talk's). True when the film took the event.
func skip_input(event: InputEvent) -> bool:
	if current == null:
		return false
	if kind == "bird" and game.dialogue.talking != "":
		return false
	var skip: bool = event.is_action_pressed(CityInput.MENU) or event.is_action_pressed(CityInput.INTERACT) \
		or event.is_action_pressed(CityInput.HANDBRAKE) or (event is InputEventMouseButton and event.pressed)
	if kind == "opening":
		skip = skip or event.is_action_pressed("ui_accept")
	if skip:
		current.skip()
	return true


# ------------------------------------------------------------------ the opening (M005)

## A new game: Danny tells you who he is while the camera drifts over the ward
## at night, already alive; the HUD, the player and the clock wait, the night's
## sound steps back under his voice. Without the recording the game simply starts.
func start_opening(copper_owl: InteriorPlan) -> void:
	var resolver := game.resolver
	var stream := resolver.get_audio("voice/danny_opening")
	var opening := Opening.new()
	game.root.add_child(opening)
	var length := stream.get_length() if stream != null else 0.0
	var keys := OpeningScript.shots(game.layout, copper_owl, game.walker.global_position, length)
	var subtitles := not resolver.has_audio_override("voice/danny_opening")
	if not opening.start(stream, keys, subtitles, load(Hud.FONT_PATH)):
		opening.queue_free()
		return
	hand_over("opening", opening, 2.4)
	game.camera.zoom_override = opening.zoom
	game.camera.snap_to(opening.rig)
	opening.finished.connect(_end_opening)


## The monologue is over (or skipped): Danny is yours.
func _end_opening() -> void:
	take_back(game.walker)
	game.save()  # the game is under way: a later start loads it, without the opening
