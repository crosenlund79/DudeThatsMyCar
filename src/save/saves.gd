class_name Saves
extends RefCounted
## M014 (from main): the save in the game - read once at start-up (migrated to
## the current format and checked: SaveSchema), its sections handed to their
## owners at the points of the build where those exist (SaveSchema.RESTORE_ORDER),
## and written by asking each owner for its section, in one fixed order. The
## file itself is SaveGame (JSON in user://). Saving stays as it was: after
## deals, hands, films, on sleeping and on quitting; one file.

var game: Game
## The save as read at start-up, at the current version and checked ({} for a new game).
var loaded := {}
## What the checks dropped from it (shown nowhere in the game; for tests and the log).
var problems: Array[String] = []
## The version the file was written at (0: no save).
var read_version := 0


func _init(p_game: Game) -> void:
	game = p_game


## Reads, migrates and checks the save at `path` ("" or no file: a new game).
func read(path: String) -> void:
	var raw := SaveGame.read(path)
	read_version = SaveSchema.version_of(raw)
	var checked := SaveSchema.validate(SaveSchema.migrate(raw))
	loaded = checked.data
	problems = checked.problems
	for p in problems:
		push_warning("Save %s: %s" % [path, p])


func is_new_game() -> bool:
	return loaded.is_empty()


func has(section: String) -> bool:
	return loaded.has(section)


## A section of the save as read (`default` when it has none).
func section(section_name: String, default: Variant = {}) -> Variant:
	return loaded.get(section_name, default)


## The game as it stands, section by section from each owner (SaveSchema.SECTIONS).
func collect() -> Dictionary:
	var g := game
	var data := {"rackets": g.rackets.to_dict(), "voices": g.voice_lines.to_dict(), "poker": {}}
	g.back_rooms.save_into(data)  # the tables: the card game, the machines, his chips counted as his money
	if g.walker != null:
		data["danny"] = g.walker.condition.to_dict()
	if g.rival != null:
		data["ward"] = {"out": g.casualties.ward_out.duplicate(), "rival": g.rival.to_dict()}
	g.armoury.save_into(data)  # the .45's rounds; M010: the Thompson's with the loan
	if g.world != null:
		data["districts"] = g.districts.to_save()
	if g.fleet != null and g.fleet.thefts != null:
		data["cars"] = g.fleet.to_save()  # M013: where the cars stand, which are taken, the one he sits in
	var walker := g.walker
	if walker != null and g.clock != null:  # M012: where and when (in the street or in a room, any district)
		var player := g.player
		var at: Vector2 = walker.global_position if player == null or player.on_foot() else player.body().global_position
		data["place"] = {"night": g.rackets.night, "minute": g.clock.minute, "x": at.x, "y": at.y, "facing": walker.model.facing}
	if g.incidents != null:
		data["incidents"] = g.incidents.to_dict()
	return data


## Writes the game to `path` ("" writes nothing).
func write(path: String) -> bool:
	return SaveGame.write(path, collect())
