class_name CarWheels
extends Node2D
## The two front tyres of a car, drawn under its body and turned by the
## steering wheel (CarModel.wheel_angle), so you can see a car steer even
## while it stands still. Presentation only: reads the car, never changes it.

const LOGICAL := "cars/wheel"

var car: Car
var wheels: Array[Sprite2D] = []


## Adds the tyres between the car's shadow and its body.
func setup(p_car: Car, texture: Texture2D) -> void:
	car = p_car
	name = "Wheels"
	var v := car.vehicle
	for side in [-1.0, 1.0]:
		var s := Sprite2D.new()
		s.texture = texture
		s.scale = AssetCatalog.scale_for(texture, AssetCatalog.display_size(LOGICAL))
		s.position = Vector2(v.front_axle_x, side * v.wheel_half_track)
		add_child(s)
		wheels.append(s)
	car.add_child(self)
	car.move_child(self, car.get_node("Sprite").get_index())


func _process(_delta: float) -> void:
	if car == null or car.model == null:
		return
	var a := car.model.wheel_angle()
	for w in wheels:
		w.rotation = a
