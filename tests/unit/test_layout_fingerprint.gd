extends GutTest
## M014: the physical city as it was at M013 - every district's layout (streets,
## blocks, buildings, doors, lamps, routes, parked cars, contacts, spots...) and
## every room plan, in world coordinates, serialised field by field. Recorded on
## the M013 code (tests/golden/m013/layouts.json); whatever M014 changes in how
## districts are written down (local coordinates, named places), the city they
## describe must be the same to the hundredth of a pixel.
##
## Record (reference build only): GOLDEN_RECORD=1 godot ... -gtest=res://tests/unit/test_layout_fingerprint.gd

const GOLDEN := "res://tests/golden/m015/layouts.json"  # (M013 recording kept in tests/golden/m013/)


func _r(x: float) -> float:
	return snappedf(x, 0.01)


## A plain, JSON-ready copy of `x`: script objects by their script variables
## (not the ones made lazily for drawing), vectors and rects as numbers.
func _plain(x: Variant, depth: int = 0) -> Variant:
	if depth > 12:
		return "<deep>"
	match typeof(x):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return x
		TYPE_STRING_NAME:
			return String(x)
		TYPE_INT:
			return float(x)
		TYPE_FLOAT:
			return _r(x)
		TYPE_VECTOR2, TYPE_VECTOR2I:
			return [_r(x.x), _r(x.y)]
		TYPE_RECT2, TYPE_RECT2I:
			return [_r(x.position.x), _r(x.position.y), _r(x.size.x), _r(x.size.y)]
		TYPE_COLOR:
			return [_r(x.r), _r(x.g), _r(x.b), _r(x.a)]
		TYPE_DICTIONARY:
			var out := {}
			for k in x:
				out[str(k)] = _plain(x[k], depth + 1)
			return out
		TYPE_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_INT64_ARRAY:
			var out := []
			for e in x:
				out.append(_plain(e, depth + 1))
			return out
		TYPE_OBJECT:
			if x == null:
				return null
			if x is Resource and (x as Resource).resource_path != "":
				return (x as Resource).resource_path
			var out := {}
			for p in (x as Object).get_property_list():
				if not (int(p.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
					continue
				var key := String(p.name)
				if key in SKIP:
					continue
				out[key] = _plain((x as Object).get(key), depth + 1)
			return out
	return str(x)


## Caches made on demand for drawing (their content is checked through the
## data they are made from) and the M014 additions, which are new names for
## places already in the data.
const SKIP := ["_grime_made", "grime", "_shadow_tris", "_fog_tris", "_fog_cover", "places", "_places"]


func _fingerprint() -> Dictionary:
	var ward := RiversideWard.create()
	var out := {}
	for l in CityPlan.layouts(ward):
		out[(l as DistrictLayout).id] = _plain(l)
	return out


func _flat(x: Variant, path: String, out: Dictionary) -> void:
	if x is Dictionary:
		for k in x:
			_flat(x[k], path + "/" + str(k), out)
	elif x is Array:
		out[path + "#"] = (x as Array).size()
		for i in (x as Array).size():
			_flat(x[i], path + "[%d]" % i, out)
	else:
		out[path] = x


func test_the_city_is_where_it_was() -> void:
	var now := _fingerprint()
	if OS.get_environment("GOLDEN_RECORD") == "1":
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN.get_base_dir()))
		var f := FileAccess.open(GOLDEN, FileAccess.WRITE)
		f.store_string(JSON.stringify(now, "", true))
		f.close()
		pass_test("recorded")
		return
	assert_true(FileAccess.file_exists(GOLDEN), "the M013 recording")
	var want: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	var a := {}
	var b := {}
	_flat(want, "", a)
	_flat(JSON.parse_string(JSON.stringify(now)), "", b)
	var diffs := []
	for k in a:
		if not b.has(k):
			diffs.append("%s: %s -> (missing)" % [k, a[k]])
		elif a[k] != b[k]:
			diffs.append("%s: %s -> %s" % [k, a[k], b[k]])
	for k in b:
		if not a.has(k):
			diffs.append("%s: (missing) -> %s" % [k, b[k]])
	assert_eq(diffs.size(), 0, "%d differences: %s" % [diffs.size(), "\n".join(diffs.slice(0, 25))])
