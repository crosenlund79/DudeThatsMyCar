class_name VehicleType
extends Resource
## One kind of car: its handling, look and the size of its body. The look is a
## replaceable image per paint scheme (logical names, see AssetCatalog).

@export var id := "sedan"
@export var params: DrivingParams
## Paint schemes: logical image names, nose pointing right (+X).
@export var paints: PackedStringArray = PackedStringArray(["cars/sedan"])
## Body size on screen (world px, nose along +X); the image is scaled to it.
@export var size := Vector2(80, 36)
## Collision capsule (length, width), a little inside the painted body.
@export var collision := Vector2(76, 30)
## Lamps in car space (px, nose +X, y down): headlights and tail lights.
@export var headlights := PackedVector2Array([Vector2(34, -9), Vector2(34, 9)])
@export var taillights := PackedVector2Array([Vector2(-32, -12), Vector2(-32, 12)])
## Front wheels (drawn separately, they turn with the steering): axle
## position along the car and each wheel's distance from the centre line
## (display px, car centre, nose +X).
@export var front_axle_x := 22.0
@export var wheel_half_track := 17.0
## Engine sound character (pitch multiplier on the shared engine sound).
@export var engine_pitch := 1.0
## M009: a long body's collision as a box (`collision`) with its corners cut
## this much (px) instead of a capsule - a bus is not a cigar. < 0: the capsule.
@export var collision_chamfer := -1.0
## M009: the front tyres' size on screen (Vector2.ZERO: the cars/wheel default).
@export var wheel_size := Vector2.ZERO
