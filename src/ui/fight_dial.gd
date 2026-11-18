class_name FightDial
extends Control
## A fistfight on screen (M007): the brass dial over the street, the zone lit
## on its dark track, the needle sweeping round from the top. Space when the
## needle is in the zone. Five pips below keep the score; each result shows
## for a moment (a landed punch in gold, a punch taken in red) with a word or
## two. Drives a FistFight and tells the game how each check and the fight
## went; it never moves anybody. Pauses with the game.

signal check_done(hit: bool, index: int)
signal finished(won: bool, results: Array)

const SIZE := 210.0
const ZONE := Color("f2dfa0")
const HIT := Color("ffd86a")
const MISS := Color("c4423a")
const CREAM := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.55)
const LANDED := ["A jab to the jaw!", "Blocked his hook!", "Inside his guard!", "Rocked him!", "Right on the button!"]
const TAKEN := ["Swung at air!", "One in the ribs!", "He slipped it!", "A hook to the ear!", "Seeing stars!"]

var fight: FistFight
var opponent := ""
var centre := Vector2.ZERO
var message := ""
var _last_hit := false
var _flash := 0.0
var _dial: Texture2D
var _needle: Texture2D
var _font: Font


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "FightDial"
	_dial = resolver.get_texture("ui/fight_dial")
	_needle = resolver.get_texture("ui/fight_needle")
	_font = font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	visible = false


func start(p_fight: FistFight, p_opponent: String) -> void:
	fight = p_fight
	opponent = p_opponent
	message = ""
	_flash = 0.0
	visible = true
	queue_redraw()


func active() -> bool:
	return visible and fight != null and not fight.is_over()


## Space.
func press() -> void:
	if not active():
		return
	var out := fight.press()
	if out != "":
		_result(out == "hit")


func _process(delta: float) -> void:
	if not visible or fight == null:
		return
	var screen := get_viewport().get_visible_rect().size
	size = screen
	centre = Vector2(screen.x * 0.5, screen.y * 0.5 - 178.0)  # above the two men, below the clock
	_flash = maxf(0.0, _flash - delta)
	match fight.update(delta):
		"miss":
			_result(false)
		"next":
			message = ""
		"over":
			visible = false
			finished.emit(fight.won(), fight.results.duplicate())
	queue_redraw()


func _result(hit: bool) -> void:
	_last_hit = hit
	_flash = 0.35
	var i := fight.results.size() - 1
	message = (LANDED if hit else TAKEN)[i % 5]
	check_done.emit(hit, i)


func _draw() -> void:
	if fight == null:
		return
	var r := SIZE * 0.5
	draw_circle(centre, r + 14.0, Color(0.05, 0.04, 0.03, 0.55))
	draw_texture_rect(_dial, Rect2(centre - Vector2(r, r), Vector2(SIZE, SIZE)), false)
	# the lit zone on the dark track (98 of 128 texture px from the middle)
	var track := r * 98.0 / 128.0
	var width := r * 12.0 / 128.0
	var a0 := deg_to_rad(fight.zone_start - 90.0)
	var a1 := deg_to_rad(fight.zone_start + fight.zone_width - 90.0)
	var zone := ZONE
	if fight.phase == FistFight.Phase.FEEDBACK:
		zone = HIT if _last_hit else MISS
	draw_arc(centre, track, a0, a1, 32, Color(zone, 0.25), width * 2.2, true)
	draw_arc(centre, track, a0, a1, 32, zone, width, true)
	# the needle
	draw_set_transform(centre, deg_to_rad(fight.needle), Vector2.ONE)
	draw_texture_rect(_needle, Rect2(-Vector2(r, r), Vector2(SIZE, SIZE)), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _flash > 0.0:
		draw_circle(centre, r * 0.3, Color(HIT if _last_hit else MISS, _flash * 1.6))
	# the score: five pips
	var n := fight.rules.checks
	for i in n:
		var p := centre + Vector2((i - (n - 1) * 0.5) * 24.0, r + 16.0)
		if i < fight.results.size():
			draw_circle(p, 8.0, HIT if fight.results[i] else MISS)
		else:
			draw_arc(p, 8.0, 0.0, TAU, 20, CREAM if i == fight.index else DIM, 2.0, true)
	if _font != null:
		var at := centre + Vector2(r + 22.0, 6.0)  # beside the dial, clear of the clock
		draw_string_outline(_font, at, opponent.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color("1b1611"))
		draw_string(_font, at, opponent.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, CREAM)
		if message != "":
			_text(centre + Vector2(0, r + 44.0), message, 18, HIT if _last_hit else MISS)
		elif fight.phase == FistFight.Phase.RUNNING or fight.phase == FistFight.Phase.LEAD_IN:
			_text(centre + Vector2(0, r + 44.0), "SPACE", 15, DIM)


func _text(c: Vector2, s: String, px: int, col: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	draw_string_outline(_font, c - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, 5, Color("1b1611"))
	draw_string(_font, c - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
