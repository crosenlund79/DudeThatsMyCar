class_name WeatherView
extends Node2D
## M010: the weather where Danny can see it. Rain: a screen-wide layer of
## falling streaks and splashes under the HUD (one shader). Fog: drifting banks
## over each built district's open ground (City.fog_layer: streets, pavements,
## alleys, lots - never inside a building or a room), over the people and the
## cars but under the walls and the roofs (Layers.Z_STEAM + 1), lit by the
## lamps and headlights, banked thicker at the buildings' feet. Presentation
## only: Weather holds the levels.

const RAIN_LAYER := 2  # under the night's vignette (3) and the HUD (10)
const FOG_COLOR := Color(0.66, 0.7, 0.78)
## M013: the rain's three depths (as in rain.gdshader): how near each is (its
## scale on screen), how much it moves when the camera pans (1: like the street;
## the nearer drops, between the camera and the street, a little more), and the
## pattern's cell and period (the anchors wrap at CELL x PERIOD, which the
## shader's hash repeats on exactly, so the wrap never shows).
const RAIN_NEAR := [1.0, 0.72, 0.5]
const RAIN_PARALLAX := [1.22, 1.1, 1.0]
const RAIN_CELL := Vector2(12.0, 110.0)
const RAIN_PERIOD := 1024.0
## Screen px a second at the nearest depth: steady rain, and what a full downpour adds.
const RAIN_SPEED := 980.0
const DOWNPOUR_SPEED := 420.0
## A splash cell on the street (world px), how fast a ring spreads (a second).
const SPLASH_CELL := 34.0
const SPLASH_RATE := 1.4

var model: Weather
var rain_rect: ColorRect
var fog_material: ShaderMaterial
## M012: the fog at the buildings' feet (kept out of an open room like the street fog).
var feet_material: ShaderMaterial
## M012: the building whose room Danny is in (its roof off): no rain, no fog
## in it (Rect2() for none - in the street).
var indoors := Rect2()
## M012: a lightning flash fading out (0..1).
var flash := 0.0
var _rain_mat: ShaderMaterial
## M013: where each depth's drops stand (shader cell units x CELL, wrapped), how
## far the splashes have spread, and the camera's last centre (Vector2.INF: none yet).
var anchors: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
var splash_time := 0.0
var _last_eye := Vector2.INF


func setup(p_model: Weather, fog_banks: Texture2D = null) -> void:
	name = "Weather"
	model = p_model
	var layer := CanvasLayer.new()
	layer.name = "Rain"
	layer.layer = RAIN_LAYER
	add_child(layer)
	rain_rect = ColorRect.new()
	rain_rect.name = "Rainfall"
	rain_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rain_mat = ShaderMaterial.new()
	_rain_mat.shader = load("res://src/weather/rain.gdshader")
	rain_rect.material = _rain_mat
	layer.add_child(rain_rect)
	# the fog's look, shared by every district's fog layer (City.fog_layer, over its open ground)
	fog_material = ShaderMaterial.new()
	fog_material.shader = load("res://src/weather/fog.gdshader")
	fog_material.set_shader_parameter("fog_color", FOG_COLOR)
	fog_material.set_shader_parameter("banks_tex", fog_banks)
	feet_material = ShaderMaterial.new()
	feet_material.shader = load("res://src/weather/fog_feet.gdshader")
	refresh(Rect2(0, 0, 1, 1), Vector2.ZERO, 1.0, [])


## Every frame: the levels on screen. `eye` the camera's centre, `zoom` its
## zoom; `cities` the built districts (their fog, its banks at the buildings'
## feet, their wet streets).
func refresh(view: Rect2, eye: Vector2, zoom: float, cities: Array, delta: float = 0.0) -> void:
	var r := model.rain_strength()
	var f := model.fog
	flash = move_toward(flash, 0.0, delta / 0.35)
	rain_rect.visible = r > 0.001 or flash > 0.001
	_rain_mat.set_shader_parameter("intensity", r)
	fall(eye, zoom, delta)  # M013
	_rain_mat.set_shader_parameter("slant", model.wind())  # M012
	_rain_mat.set_shader_parameter("heavy", model.downpour())
	_rain_mat.set_shader_parameter("flash", flash * (0.35 if indoors.has_area() else 1.0))
	_rain_mat.set_shader_parameter("hole", rain_hole(view))
	var hole := Vector4(indoors.position.x, indoors.position.y, indoors.size.x, indoors.size.y)
	fog_material.set_shader_parameter("density", f)
	fog_material.set_shader_parameter("hole", hole)
	feet_material.set_shader_parameter("hole", hole)
	for c in cities:
		(c as City).set_weather(model.rain, f, FOG_COLOR, fog_material, feet_material)
	VehicleLights.wet = model.rain


## M013: moves the rain on by `delta` seconds: each depth falls at its own
## speed (faster in a downpour - integrated here, so a change of speed only
## changes how fast the drops go, never where they are), and moves with the
## street as the camera pans (`eye` its centre, `zoom`). Everything wraps at
## the pattern's period, so the numbers stay small however long the night.
func fall(eye: Vector2, zoom: float, delta: float) -> void:
	var speed := RAIN_SPEED + DOWNPOUR_SPEED * model.downpour()
	var moved := Vector2.ZERO
	if _last_eye != Vector2.INF and eye.distance_to(_last_eye) < 1500.0:  # a jump (a snap, a load) moves nothing
		moved = (eye - _last_eye) * zoom  # the street slid this far the other way on screen
	_last_eye = eye
	var period := RAIN_CELL * RAIN_PERIOD
	for i in anchors.size():
		var near: float = RAIN_NEAR[i]
		var a := anchors[i] + moved * float(RAIN_PARALLAX[i]) / near - Vector2(0.0, speed * delta)
		anchors[i] = Vector2(fposmod(a.x, period.x), fposmod(a.y, period.y))
	splash_time = fposmod(splash_time + delta * (SPLASH_RATE + 0.8 * model.downpour()), 1.0)
	var screen := rain_rect.size if rain_rect.size.x > 1.0 else Vector2(1280, 720)
	var cell := SPLASH_CELL * zoom
	var under := Vector2(fposmod(eye.x / SPLASH_CELL, RAIN_PERIOD), fposmod(eye.y / SPLASH_CELL, RAIN_PERIOD))
	_rain_mat.set_shader_parameter("screen_size", screen)
	_rain_mat.set_shader_parameter("anchor_near", anchors[0])
	_rain_mat.set_shader_parameter("anchor_mid", anchors[1])
	_rain_mat.set_shader_parameter("anchor_far", anchors[2])
	_rain_mat.set_shader_parameter("splash_anchor", under)
	_rain_mat.set_shader_parameter("splash_cell", cell)
	_rain_mat.set_shader_parameter("splash_time", splash_time)


## M012: the open room's building as a part of the screen-wide rain rect (x,
## y, w, h in 0..1; zero size in the street). `view`: the world on screen.
func rain_hole(view: Rect2) -> Vector4:
	if not indoors.has_area() or not view.has_area():
		return Vector4.ZERO
	var a := (indoors.position - view.position) / view.size
	var b := (indoors.end - view.position) / view.size
	return Vector4(a.x, a.y, b.x - a.x, b.y - a.y)


## M012: lightning - the street lit cold for a breath (a near clap brighter).
func lightning(near: bool) -> void:
	flash = 1.0 if near else 0.55
