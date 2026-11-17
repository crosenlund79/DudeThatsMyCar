class_name SaveGame
extends RefCounted
## The player's progress in one small JSON file (money, bottles, rounds,
## which night it is and what has happened tonight). An empty path means no
## saving at all (tests).

const DEFAULT_PATH := "user://chicago1932_save.json"
const VERSION := 1


static func write(path: String, data: Dictionary) -> bool:
	if path == "":
		return false
	var out := data.duplicate()
	out["version"] = VERSION
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(out, "\t"))
	return true


## The saved data, or {} when there is none (or it cannot be read).
static func read(path: String) -> Dictionary:
	if path == "" or not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}
