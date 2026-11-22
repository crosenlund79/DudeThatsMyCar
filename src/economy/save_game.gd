class_name SaveGame
extends RefCounted
## The player's progress in one small JSON file (the sections and their owners:
## SaveSchema; reading, checking and writing them: Saves). An empty path means
## no saving at all (tests).

const DEFAULT_PATH := "user://chicago1932_save.json"


static func write(path: String, data: Dictionary) -> bool:
	if path == "":
		return false
	var out := data.duplicate()
	out["version"] = SaveSchema.VERSION
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(out, "\t"))
	return true


## The saved data, or {} when there is none (or it cannot be read). M014: a
## file that is there but cannot be read as a save is kept beside it
## (`<name>.unreadable.json`) before the game starts afresh and, in time,
## writes over it - so nothing is lost without a copy.
static func read(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var json := JSON.new()  # (parse quietly: a broken file is handled below, not an engine error)
	if json.parse(text) == OK and json.data is Dictionary:
		return json.data
	keep_unreadable(path, text)
	return {}


## Where an unreadable save is kept (beside it).
static func unreadable_path(path: String) -> String:
	return path.get_basename() + ".unreadable." + path.get_extension()


static func keep_unreadable(path: String, text: String) -> void:
	var copy := FileAccess.open(unreadable_path(path), FileAccess.WRITE)
	if copy != null:
		copy.store_string(text)
		copy.close()
	push_warning("Save %s could not be read; kept as %s. Starting afresh." % [path, unreadable_path(path)])
