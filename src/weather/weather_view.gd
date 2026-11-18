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
	refresh(Rect2(0, 0, 1, 1), Vector2.ZERO, 1.0, [])


## Every frame: the levels on screen. `eye` the camera's centre, `zoom` its
## zoom; `cities` the built districts (their fog, its banks at the buildings'
## feet, their wet streets).
func refresh(_view: Rect2, eye: Vector2, zoom: float, cities: Array) -> void:
	var r := model.rain_strength()
	var f := model.fog
	rain_rect.visible = r > 0.001
	_rain_mat.set_shader_parameter("intensity", r)
	_rain_mat.set_shader_parameter("offset", eye)
	_rain_mat.set_shader_parameter("zoom", zoom)
	fog_material.set_shader_parameter("density", f)
	for c in cities:
		(c as City).set_weather(model.rain, f, FOG_COLOR, fog_material)
	VehicleLights.wet = model.rain
