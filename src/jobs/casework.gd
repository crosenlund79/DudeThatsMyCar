class_name Casework
extends RefCounted
## M015: the game side of Danny's case sheets (Casebook): twice a second the
## sheets are drawn up again from what he knows, and the work they point to is
## placed - in the street (WorkMarkers: a quiet badge near it), at the edge of
## the view (WorkArrows: known work out of sight), on the minimap and on the
## city map. A mark inside a room is shown at the person in it while Danny is
## in that room, at the room's street door otherwise. The player can switch
## the street marks and arrows off (the Notebook page; kept with the other
## preferences); the maps keep theirs.

const EVERY := 0.5
const PREF := "work_markers"

var game: Game
var markers: WorkMarkers
## The sheets as last drawn up, and their marks placed: [{pos, label, sure, case}].
var sheets: Array = []
var marks: Array = []
var _left := 0.0


func _init(p_game: Game) -> void:
	game = p_game


## The street layer (made by the game's composition root).
func attach(p_markers: WorkMarkers) -> void:
	markers = p_markers


func shown() -> bool:
	return bool(game.prefs.get_pref(PREF))


func set_shown(on: bool) -> void:
	game.prefs.set_pref(PREF, on)
	refresh()


## Draws the sheets up again now (the menu does, on opening; the clock twice a second).
func refresh() -> void:
	sheets = Casebook.cases(game.rackets, game.clock.minute)
	marks = place(Casebook.marks(sheets))
	var on := shown()
	if markers != null:
		markers.marks = marks
		markers.shown = on
	var hud := game.hud
	if hud != null:
		if hud.work_arrows != null:
			hud.work_arrows.marks = marks
			hud.work_arrows.shown = on
		if hud.minimap != null:
			hud.minimap.work = marks
		if hud.city_map != null:
			hud.city_map.work = marks
			hud.city_map.work_cases = sheets.filter(func(c: Dictionary) -> bool: return c.status == Casebook.OPEN).map(
				func(c: Dictionary) -> String: return String(c.title))


## The marks in the world: each at its inside place while Danny is in that room, else at its street place.
func place(raw: Array) -> Array:
	var out := []
	var room := game.interiors.current.id if game.interiors != null and game.interiors.current != null else ""
	for m in raw:
		var id := String(m.at)
		var inside := String(m.inside)
		if inside != "" and room != "" and inside.contains("/spot/%s/" % room):
			id = inside
		if not game.locations.has(id):
			continue
		out.append({"pos": game.locations.at(id), "label": m.label, "sure": m.sure, "case": m.case})
	return out


func update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = EVERY
		refresh()
	if markers != null:
		var focus := game.player.body().global_position
		markers.update_marks(delta, game.camera.eye(), game.camera.eye_height(), focus)
	if game.hud != null and game.hud.work_arrows != null:
		game.hud.work_arrows.focus = game.player.body().global_position
