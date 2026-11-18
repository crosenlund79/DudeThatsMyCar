class_name DrowsyView
extends CanvasLayer
## M010: towards dawn Danny's eyes grow heavy - a dark vignette that closes in
## from the edges and breathes, a slow heavy blink now and then, and the view
## drifting a little as if he were swaying on his feet (much less at the
## wheel). Under the HUD, so nothing on it is covered. It eases away while he
## talks, plays cards or a scene is being shown, and is gone after sleeping
## (it follows the clock). Presentation only: NightClock.drowsiness() says how
## tired he is.

const LAYER := 4
## The drift at its strongest (px of camera offset), on foot and at the wheel.
const SWAY_FOOT := 11.0
const SWAY_CAR := 2.5
## Seconds between heavy blinks at dawn, and when they begin.
const BLINK_EVERY := 16.0
const BLINK_FROM := 0.55
const BLINK_TIME := 1.4

var rect: ColorRect
var effect := 0.0
var _mat: ShaderMaterial
var _time := 0.0


func setup() -> void:
	name = "Drowsiness"
	layer = LAYER
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://src/ui/drowsy.gdshader")
	rect.material = _mat
	add_child(rect)
	rect.visible = false


## Every frame: `level` how tired he is (0..1), `held` true while the effect
## must keep out of the way (talk, cards, a scene). Returns the camera's drift.
func update(level: float, held: bool, driving: bool, delta: float) -> Vector2:
	_time += delta
	effect = move_toward(effect, 0.0 if held else level, delta / 1.2)
	rect.visible = effect > 0.001
	var blink := 0.0
	if effect > BLINK_FROM:
		var every := lerpf(BLINK_EVERY * 1.8, BLINK_EVERY, (effect - BLINK_FROM) / (1.0 - BLINK_FROM))
		var phase := fmod(_time, every)
		if phase < BLINK_TIME:
			blink = sin(phase / BLINK_TIME * PI)
	_mat.set_shader_parameter("level", effect)
	_mat.set_shader_parameter("blink", blink)
	_mat.set_shader_parameter("breath", sin(_time * 0.9))
	var amp := (SWAY_CAR if driving else SWAY_FOOT) * effect
	return Vector2(sin(_time * 0.53) + 0.4 * sin(_time * 1.31), cos(_time * 0.41) * 0.8 + 0.3 * sin(_time * 0.97)) * amp
