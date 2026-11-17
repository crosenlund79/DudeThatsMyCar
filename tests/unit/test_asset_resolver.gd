extends GutTest
## AssetResolver contract (assets/README.md): override precedence, missing and invalid
## fallback, supported format, override-root selection, caching, catalogue coverage.

const CAR := "cars/sedan"

var _root: String


func before_each() -> void:
	_root = OS.get_user_data_dir().path_join("test_overrides_%d" % Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(_root.path_join("graphics/cars"))


func after_each() -> void:
	_remove_dir(_root)


func _remove_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_remove_dir(path.path_join(sub))
	for file in dir.get_files():
		dir.remove(file)
	DirAccess.remove_absolute(path)


func _write_png(rel: String, size: Vector2i) -> void:
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color.MAGENTA)
	img.save_png(_root.path_join(rel))


func _write_bytes(rel: String, bytes: PackedByteArray) -> void:
	var f := FileAccess.open(_root.path_join(rel), FileAccess.WRITE)
	f.store_buffer(bytes)
	f.close()


func test_valid_png_override_takes_precedence() -> void:
	_write_png("graphics/cars/sedan.png", Vector2i(256, 144))
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_eq(tex.get_size(), Vector2(256, 144))


func test_missing_override_uses_template() -> void:
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_not_null(tex)
	assert_eq(tex.resource_path, "res://assets/graphics/cars/template_sedan.png")


func test_non_png_content_falls_back_with_warning() -> void:
	_write_bytes("graphics/cars/sedan.png", "not an image".to_utf8_buffer())
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_eq(tex.resource_path, "res://assets/graphics/cars/template_sedan.png")
	assert_push_warning_count(1)


func test_corrupt_png_falls_back_with_warning() -> void:
	var bytes := PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4])
	_write_bytes("graphics/cars/sedan.png", bytes)
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_eq(tex.resource_path, "res://assets/graphics/cars/template_sedan.png")
	assert_push_warning_count(1)
	# The engine's PNG decoder logs its own error for the corrupt buffer.
	for e in get_errors():
		e.handled = true


func test_unsupported_extension_is_not_used() -> void:
	_write_png("graphics/cars/sedan.jpg", Vector2i(8, 8))
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_eq(tex.resource_path, "res://assets/graphics/cars/template_sedan.png")


func test_results_are_cached_for_the_session() -> void:
	var r := AssetResolver.new(_root)
	var first := r.get_texture(CAR)
	_write_png("graphics/cars/sedan.png", Vector2i(16, 16))
	assert_same(r.get_texture(CAR), first, "changes apply after restart only")


func test_override_root_selection() -> void:
	assert_eq(AssetResolver.compute_override_root(true, "/opt/godot/godot", "/proj/custom"), "/proj/custom")
	assert_eq(AssetResolver.compute_override_root(false, "/games/HyperCars/HyperCars.x86_64", "/proj/custom"),
		"/games/HyperCars/custom")
	assert_eq(AssetResolver.compute_override_root(false, "C:/Games/HyperCars/HyperCars.exe", "/proj/custom"),
		"C:/Games/HyperCars/custom")


func test_default_root_in_editor_is_project_custom_folder() -> void:
	if not OS.has_feature("editor"):
		pending("Only meaningful when running with the editor binary")
		return
	assert_eq(AssetResolver.new().override_root, ProjectSettings.globalize_path("res://custom"))


func test_fallback_path_mapping() -> void:
	assert_eq(AssetResolver.fallback_path("track/tarmac"), "res://assets/graphics/track/template_tarmac.png")
	assert_eq(AssetResolver.fallback_path("logo"), "res://assets/graphics/template_logo.png")


func test_every_catalogued_asset_has_a_template_of_declared_size() -> void:
	var r := AssetResolver.new(_root)
	for logical_name in AssetCatalog.SPECS:
		var tex := r.get_texture(logical_name)
		assert_not_null(tex, logical_name)
		if tex != null:
			assert_eq(Vector2i(tex.get_size()), AssetCatalog.SPECS[logical_name].template_size, logical_name)


func test_override_of_any_resolution_scales_to_display_size() -> void:
	var display: Vector2 = AssetCatalog.SPECS[CAR].display_size
	_write_png("graphics/cars/sedan.png", Vector2i(512, 288))
	var tex := AssetResolver.new(_root).get_texture(CAR)
	assert_eq(Vector2(tex.get_size()) * AssetCatalog.scale_for(tex, display), display)


func test_facade_override_of_any_resolution_is_used() -> void:
	DirAccess.make_dir_recursive_absolute(_root.path_join("graphics/facades"))
	_write_png("graphics/facades/brick_red.png", Vector2i(512, 384))
	var r := AssetResolver.new(_root)
	assert_true(r.has_override("facades/brick_red"))
	assert_eq(r.get_texture("facades/brick_red").get_width(), 512, "the user's facade, at its own resolution")
	assert_false(r.has_override("facades/brick_red_lit"), "its window light keeps the template")
	assert_eq(r.get_texture("facades/brick_red_lit").get_width(), 256)


func test_character_sheet_override_keeps_the_frame_size_on_screen() -> void:
	DirAccess.make_dir_recursive_absolute(_root.path_join("graphics/characters"))
	_write_png("graphics/characters/gangster.png", Vector2i(640, 128))
	var tex := AssetResolver.new(_root).get_texture("characters/gangster")
	var spec: Dictionary = AssetCatalog.SPECS["characters/gangster"]
	var frame := Vector2(tex.get_size()) / Vector2(spec.frames, 1)
	assert_eq(frame * AssetCatalog.scale_for(tex, spec.display_size * Vector2(spec.frames, 1)), spec.display_size)


func _wav_bytes(samples: int) -> PackedByteArray:
	var data := PackedByteArray()
	data.resize(samples * 2)
	for k in samples:
		data.encode_s16(k * 2, int(sin(k * 0.05) * 8000.0))
	var b := PackedByteArray()
	b.append_array("RIFF".to_ascii_buffer())
	var n := PackedByteArray()
	n.resize(4)
	n.encode_u32(0, 36 + data.size())
	b.append_array(n)
	b.append_array("WAVEfmt ".to_ascii_buffer())
	var fmt := PackedByteArray()
	fmt.resize(20)
	fmt.encode_u32(0, 16)
	fmt.encode_u16(4, 1)  # PCM
	fmt.encode_u16(6, 1)  # mono
	fmt.encode_u32(8, 22050)
	fmt.encode_u32(12, 44100)
	fmt.encode_u16(16, 2)
	fmt.encode_u16(18, 16)
	b.append_array(fmt)
	b.append_array("data".to_ascii_buffer())
	n.encode_u32(0, data.size())
	b.append_array(n)
	b.append_array(data)
	return b


func test_audio_override_takes_precedence_and_missing_falls_back() -> void:
	var r := AssetResolver.new(_root)
	assert_false(r.has_audio_override("vehicles/impact_car"))
	var template := r.get_audio("vehicles/impact_car")
	assert_not_null(template, "packaged template")
	DirAccess.make_dir_recursive_absolute(_root.path_join("audio/vehicles"))
	_write_bytes("audio/vehicles/impact_car.wav", _wav_bytes(4410))
	var r2 := AssetResolver.new(_root)
	assert_true(r2.has_audio_override("vehicles/impact_car"))
	var stream := r2.get_audio("vehicles/impact_car")
	assert_true(stream is AudioStreamWAV, "the user's WAV is loaded at runtime")
	assert_almost_eq(stream.get_length(), 0.2, 0.01)


func test_every_catalogued_sound_has_a_template() -> void:
	var r := AssetResolver.new(_root)
	for logical in AssetCatalog.AUDIO:
		assert_not_null(r.get_audio(logical, AssetCatalog.AUDIO[logical].loop), logical)
