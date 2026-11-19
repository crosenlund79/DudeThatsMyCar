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
	_rain_mat.set_shader_parameter("offset", eye)
	_rain_mat.set_shader_parameter("zoom", zoom)
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
