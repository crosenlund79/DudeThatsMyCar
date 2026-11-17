class_name SoftShadow
extends RefCounted
## One shared soft, round contact shadow (drawn under cars and people,
## stretched to their size). Generated once; it is lighting, not artwork.

static var _texture: Texture2D


static func texture() -> Texture2D:
	if _texture == null:
		var size := 64
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				var d := Vector2(x + 0.5 - size * 0.5, y + 0.5 - size * 0.5).length() / (size * 0.5)
				var a := clampf(1.0 - d, 0.0, 1.0)
				img.set_pixel(x, y, Color(0.02, 0.02, 0.04, a * a * 0.85))
		_texture = ImageTexture.create_from_image(img)
	return _texture
