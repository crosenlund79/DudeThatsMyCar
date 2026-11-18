class_name StatusScreen
extends Control
## How Danny is (M006, C key): his figure from the front in six pieces - head,
## body, both arms, both legs - each tinted by how badly it is hurt, with the
## word for it beside, and what the wounds do to him (a limp, an unsteady gun
## hand). Not an inventory. Presentation only: the game is paused while it is open.

const REGIONS := ["head", "torso", "right_arm", "left_arm", "right_leg", "left_leg"]
const TINT := [Color("d9d2c2"), Color("e8b450"), Color("e0663a"), Color("b8241c")]
const PANEL := Color("1b1611", 0.94)
const INK := Color("f1e4c6")
const DIM := Color("f1e4c6", 0.6)
const COPPER := Color("d8a060")
var condition: BodyCondition
var pieces := {}
var _font: Font
var _time := 0.0
## The figure's place on screen.
var figure := Rect2()


func setup(resolver: AssetResolver, font: Font) -> void:
	name = "StatusScreen"
	_font = font
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	for r in REGIONS:
		pieces[r] = resolver.get_texture("ui/status_" + r)


func show_condition(c: BodyCondition) -> void:
	condition = c
	queue_redraw()


## The colour a region is drawn in.
func tint_of(region: String) -> Color:
	return TINT[condition.level(region)] if condition != null else TINT[0]


func layout_for(screen: Vector2) -> void:
	position = Vector2.ZERO
	size = screen
	var fig := Vector2(160, 320) * 1.5
	figure = Rect2(Vector2(screen.x * 0.5 - fig.x - 60.0, (screen.y - fig.y) * 0.5), fig)


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PANEL)
	if condition == null:
		return
	for r in REGIONS:
		var c := tint_of(r)
		if condition.level(r) == BodyCondition.Level.CRITICAL:
			c = c.lerp(Color("ff5a40"), 0.5 + 0.5 * sin(_time * 5.0))
		draw_texture_rect(pieces[r], figure, false, c)
	var x := figure.end.x + 80.0
	var y := figure.position.y + 10.0
	_text(Vector2(x, y + 20.0), "DANNY \"DIMES\" MERCER", 22, COPPER)
	y += 60.0
	for r in REGIONS:
		var lvl := condition.level(r)
		draw_rect(Rect2(x, y - 13.0, 14.0, 14.0), TINT[lvl])
		_text(Vector2(x + 24.0, y), BodyCondition.NAMES[r].capitalize(), 17, INK)
		_text(Vector2(x + 150.0, y), BodyCondition.label(lvl), 17, TINT[lvl] if lvl > 0 else DIM)
		y += 30.0
	y += 16.0
	for line in effects():
		_text(Vector2(x, y), line, 15, INK)
		y += 24.0
	y += 20.0
	_text(Vector2(x, y), "C or Esc   close", 13, DIM)


## What his wounds do to him, in words.
func effects() -> Array[String]:
	var out: Array[String] = []
	if not condition.is_hurt():
		out.append("Not a scratch on him.")
		return out
	var f := condition.speed_factor()
	if f < 0.999:
		out.append("Limping: walks at %d%% of his pace." % int(round(f * 100.0)))
	if condition.aim_spread() > 0.0:
		out.append("Unsteady gun hand: his shots wander.")
	if condition.worst() >= BodyCondition.Level.WOUNDED:
		out.append("Wounds don't heal by themselves. Doc Pettibone")
		out.append("on Pruitt Street patches up anything, for cash.")
	else:
		out.append("Grazes heal with a day's sleep.")
	return out


func _text(at: Vector2, s: String, px: int, col: Color) -> void:
	if _font != null:
		draw_string(_font, at, s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
