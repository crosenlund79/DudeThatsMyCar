extends GutTest
## M005 a new game opens with Danny's monologue over the living ward: the HUD
## and the player wait, the night steps back under his voice, subtitles follow
## the recording, any key skips it, and then he is yours. Loading a saved game
## or sleeping never plays it again, and without a recording the game just
## starts. (No sound card in the test run: the voice's audibility and its sync
## with the subtitles are listening checks in the M005 checklist.)

const MAIN := preload("res://src/main/main.tscn")

var main: Node2D
var _save := ""
var _root := ""


func before_each() -> void:
	_save = OS.get_user_data_dir().path_join("test_opening_%d.json" % Time.get_ticks_usec())
	_root = ""


func after_each() -> void:
	if is_instance_valid(main):
		main.free()
	get_tree().paused = false
	if FileAccess.file_exists(_save):
		DirAccess.remove_absolute(_save)
	if _root != "":
		_remove_dir(_root)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)


func _start(override_root := "") -> void:
	main = MAIN.instantiate()
	main.command_source = func(_c: PlayerController) -> PlayerCommand: return PlayerCommand.new()
	main.save_path = _save
	main.settings_path = ""
	main.override_root = override_root
	add_child(main)
	await wait_physics_frames(2)


func _key(action: String) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e


func test_a_new_game_opens_with_dannys_monologue_over_the_living_ward() -> void:
	await _start()
	var o: Opening = main.opening
	assert_not_null(o, "a new game begins with the opening")
	assert_true(o.running)
	assert_true(o.voice.playing, "his voice")
	assert_true(o.voice.stream is AudioStreamMP3, "the shipped recording, as recorded")
	assert_almost_eq(o.length, 23.4, 0.15, "it lasts as long as the recording")
	assert_eq(o.voice.bus, &"Voice")
	assert_eq(o.voice.volume_db, 0.0, "at its own level, unprocessed")
	assert_true(o.subtitles)
	assert_false(main.hud.visible, "no HUD over the opening")
	assert_false(main.markers.visible, "no place markers either")
	assert_false(main.player.is_physics_processing(), "Danny waits")
	assert_eq(main.camera.target, o.rig, "the camera drifts over the ward")
	assert_eq(o.subtitle.text, "Chicago. 1932.")
	var minute: float = main.clock.minute
	var walker_at: Vector2 = main.walker.global_position
	var movers: Array[Node2D] = []
	for p in main.street.pedestrians:
		if p.visible:
			movers.append(p)
	for c in main.street.traffic:
		if c.visible:
			movers.append(c)
	assert_gt(movers.size(), 0, "people and cars out on the streets")
	var was := movers.map(func(n: Node2D) -> Vector2: return n.global_position)
	await wait_physics_frames(90)
	assert_gt(main.soundscape.duck, 0.9, "the night steps back under his voice")
	assert_eq(main.clock.minute, minute, "the night waits for him")
	assert_eq(main.walker.global_position, walker_at)
	var moved := 0.0
	for i in movers.size():
		moved += movers[i].global_position.distance_to(was[i])
	assert_gt(moved, 20.0, "the ward is already alive")
	assert_true(main.soundscape.music.playing, "the singer is already singing at the Copper Owl")
	o.time = 10.0
	await wait_physics_frames(2)
	assert_eq(o.subtitle.text, "Name's Danny Mercer. They call me Dimes.")


func test_any_key_skips_it_and_hands_over() -> void:
	await _start()
	await wait_physics_frames(30)
	main._unhandled_input(_key(CityInput.INTERACT))
	assert_true(main.opening.is_handing_over())
	assert_false(main.paused)
	await wait_physics_frames(80)
	assert_null(main.opening, "over")
	assert_true(main.hud.visible)
	assert_true(main.markers.visible)
	assert_true(main.player.is_physics_processing(), "Danny is yours")
	assert_eq(main.camera.target, main.walker)
	assert_eq(main.camera.zoom_override, 0.0)
	await wait_physics_frames(60)
	assert_lt(main.soundscape.duck, 0.1, "the night comes back up")
	assert_true(FileAccess.file_exists(_save), "the game is saved as under way")
	main._unhandled_input(_key(CityInput.MENU))
	assert_true(main.paused, "and Esc pauses again as usual")


func test_esc_skips_rather_than_pausing() -> void:
	await _start()
	main._unhandled_input(_key(CityInput.MENU))
	assert_false(main.paused)
	assert_true(main.opening.is_handing_over())


func test_played_through_it_ends_on_its_own() -> void:
	await _start()
	var o: Opening = main.opening
	o.time = o.length - 1.0
	await wait_physics_frames(3)
	assert_eq(o.subtitle.text, "Well... better get to work.")
	await wait_physics_frames(180)
	assert_null(main.opening, "handed over after the last line")
	assert_true(main.player.is_physics_processing())
	assert_lt(main.camera.global_position.distance_to(main.walker.global_position), 80.0, "the camera is on Danny")


func test_a_saved_game_and_the_next_evening_start_without_it() -> void:
	await _start()
	main._unhandled_input(_key(CityInput.INTERACT))
	await wait_physics_frames(80)
	main.sleep()
	await wait_physics_frames(5)
	assert_null(main.opening, "sleeping never replays it")
	main.free()
	await _start()
	assert_null(main.opening, "loading a saved game never replays it")
	assert_true(main.hud.visible)
	assert_true(main.player.is_physics_processing())


func test_without_a_recording_the_game_just_starts() -> void:
	var o := Opening.new()
	add_child_autofree(o)
	assert_false(o.start(null, [], true, null), "nothing to play")
	assert_false(o.running)


func test_the_users_own_voice_plays_without_the_shipped_subtitles() -> void:
	_root = OS.get_user_data_dir().path_join("test_opening_root_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_root.path_join("audio/voice"))
	var f := FileAccess.open(_root.path_join("audio/voice/danny_opening.mp3"), FileAccess.WRITE)
	f.store_buffer(FileAccess.get_file_as_bytes("res://assets/audio/voice/danny_opening.mp3"))
	f.close()
	await _start(_root)
	assert_not_null(main.opening)
	assert_false(main.opening.subtitles, "the subtitles belong to the shipped recording")
	assert_eq(main.opening.subtitle.text, "")
