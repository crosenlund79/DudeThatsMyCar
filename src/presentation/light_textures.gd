class_name LightTextures
extends RefCounted
## Shared light shapes for PointLight2D (lighting, not artwork).

static var _radial: Texture2D


## Soft round pool: bright centre, long gentle falloff. 256 px across.
static func radial() -> Texture2D:
	if _radial == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.25, Color(1, 1, 1, 0.62))
		g.add_point(0.6, Color(1, 1, 1, 0.16))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.5)
		gt.fill_to = Vector2(1.0, 0.5)
		gt.width = 256
		gt.height = 256
		_radial = gt
	return _radial
