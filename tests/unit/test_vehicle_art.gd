extends GutTest
## M004 every car shows which way it faces, even with its lamps off: the
## headlamps painted where the headlights shine, red tail lamps at the back,
## and the bright chrome (radiator, mascot, bumper) and the windscreen at the
## nose, none at the tail. Checks the template_ images against the vehicle data.

const VEHICLES := ["res://src/driving/vehicles/sedan.tres", "res://src/driving/vehicles/coupe.tres",
	"res://src/driving/vehicles/police.tres"]


func _template(logical: String) -> Image:
	var parts := logical.split("/")
	var path := "res://assets/graphics/%s/template_%s.png" % [parts[0], parts[1]]
	return Image.load_from_file(ProjectSettings.globalize_path(path))


## Image pixel under a point in car space (display px, nose +X, centre 0).
func _at(img: Image, v: VehicleType, p: Vector2) -> Color:
	var scale := Vector2(img.get_size()) / v.size
	var q := (p + v.size * 0.5) * scale
	return img.get_pixel(clampi(int(q.x), 0, img.get_width() - 1), clampi(int(q.y), 0, img.get_height() - 1))


func test_headlamps_at_the_front_tail_lamps_at_the_back() -> void:
	for path in VEHICLES:
		var v: VehicleType = load(path)
		for p in v.headlights:
			assert_gt(p.x, v.size.x * 0.3, "%s: headlights at the nose" % v.id)
		for p in v.taillights:
			assert_lt(p.x, -v.size.x * 0.3, "%s: tail lamps at the back" % v.id)
		for paint in v.paints:
			var img := _template(paint)
			assert_eq(img.get_size(), Vector2i(AssetCatalog.SPECS[paint].template_size), paint)
			for p in v.headlights:
				var c := _at(img, v, p)
				assert_gt(c.get_luminance(), 0.6, "%s: a pale headlamp lens painted at %s (%s)" % [paint, p, c])
			for p in v.taillights:
				var c2 := _at(img, v, p)
				assert_true(c2.r > 0.45 and c2.r > c2.g * 1.6, "%s: a red tail lamp painted at %s (%s)" % [paint, p, c2])


func test_the_bright_chrome_is_at_the_nose() -> void:
	for path in VEHICLES:
		var v: VehicleType = load(path)
		for paint in v.paints:
			var img := _template(paint)
			var w := img.get_width()
			var front := 0
			var rear := 0
			for y in img.get_height():
				for x in w:
					var c := img.get_pixel(x, y)
					var hi := maxf(c.r, maxf(c.g, c.b))
					var lo := minf(c.r, minf(c.g, c.b))
					if c.a > 0.5 and hi > 0.72 and (hi - lo) / hi < 0.12:
						if x > w * 0.8:
							front += 1
						elif x < w * 0.2:
							rear += 1
			assert_gt(front, 60, "%s: radiator, mascot and bumper shine at the front" % paint)
			assert_lt(rear, 10, "%s: the tail stays dark (only red lamps)" % paint)
