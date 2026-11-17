class_name DrawLayer
extends Node2D
## A canvas item whose drawing is done by its owner (painter(self) in _draw),
## so one owner can draw on several z levels (walls, glow, roof).

var painter: Callable


func _init(p_painter: Callable = Callable(), z: int = 0, glow: bool = false, light_mask_bits: int = Layers.LIGHT_STREET) -> void:
	painter = p_painter
	z_index = z
	z_as_relative = false
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	light_mask = light_mask_bits
	if glow:
		material = glow_material()


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)


static var _glow_material: CanvasItemMaterial


## Additive and unshaded: light that the night tint does not darken.
static func glow_material() -> CanvasItemMaterial:
	if _glow_material == null:
		_glow_material = CanvasItemMaterial.new()
		_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_glow_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _glow_material
