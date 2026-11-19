class_name OverheadLine
extends Node2D
## M012: a few words over someone's head (a call-out): the same small cream
## type on a soft dark backing as the incidents' lines, following the speaker,
## gone after a few seconds. Presentation only.

const SECONDS := 4.5
const ABOVE := Vector2(0, -34)

var speaker: Node2D
var label: Label
var left := 0.0
## M013: raised this far above the usual (another line close by).
var lift := 0.0


func setup(font: Font) -> void:
	name = "OverheadLine"
	z_index = Layers.Z_MIST + 3
	z_as_relative = false
	label = Label.new()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("f3e3c0"))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.04, 0.04, 0.6)
	back.set_corner_radius_all(4)
	back.content_margin_left = 5.0
	back.content_margin_right = 5.0
	back.content_margin_top = 1.0
	back.content_margin_bottom = 1.0
	label.add_theme_stylebox_override("normal", back)
	add_child(label)
	visible = false


## Says `text` over `who` for a few seconds.
func say(who: Node2D, text: String) -> void:
	speaker = who
	lift = 0.0
	label.text = text
	label.reset_size()
	left = SECONDS
	visible = true
	_follow()


func hush() -> void:
	left = 0.0
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	left -= delta
	if left <= 0.0 or not is_instance_valid(speaker) or not speaker.is_visible_in_tree():
		hush()
		return
	modulate.a = clampf(left / 0.6, 0.0, 1.0)
	_follow()


func _follow() -> void:
	if is_instance_valid(speaker):
		global_position = speaker.global_position + ABOVE - Vector2(0, lift)
		label.position = Vector2(-label.size.x * 0.5, -label.size.y)
