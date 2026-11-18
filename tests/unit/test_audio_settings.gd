extends GutTest
## Volume/mute preferences: defaults, persistence, buses and the settings panel.

var _path: String


func before_each() -> void:
	_path = OS.get_user_data_dir().path_join("test_settings_%d.cfg" % Time.get_ticks_usec())


func after_each() -> void:
	if FileAccess.file_exists(_path):
		DirAccess.remove_absolute(_path)
	AudioSettings.new(_path).apply()  # restore default levels


func test_defaults_cover_all_six_buses() -> void:
	var s := AudioSettings.new(_path)
	assert_eq(AudioSettings.BUSES, ["Master", "Music", "Engine", "Effects", "Voice", "Ambience"] as Array[String])
	for bus in AudioSettings.BUSES:
		assert_between(s.volume[bus], 0.0, 1.0)
		assert_false(s.muted[bus])


func test_save_and_load_round_trip() -> void:
	var s := AudioSettings.new(_path)
	s.volume["Music"] = 0.25
	s.muted["Engine"] = true
	assert_eq(s.save_settings(), OK)
	var t := AudioSettings.new(_path)
	t.load_settings()
	assert_almost_eq(t.volume["Music"], 0.25, 0.0001)
	assert_true(t.muted["Engine"])
	assert_false(t.muted["Music"])


func test_missing_or_bad_file_keeps_defaults() -> void:
	var s := AudioSettings.new(_path)
	s.load_settings()
	assert_almost_eq(s.volume["Master"], AudioSettings.DEFAULT_VOLUME["Master"], 0.0001)
	var f := FileAccess.open(_path, FileAccess.WRITE)
	f.store_string("[audio]\nmusic_volume=7.5\n")
	f.close()
	s.load_settings()
	assert_almost_eq(s.volume["Music"], 1.0, 0.0001, "clamped")


func test_apply_creates_buses_and_sets_volume_and_mute() -> void:
	var s := AudioSettings.new(_path)
	s.set_volume("Effects", 0.5)
	s.set_muted("Music", true)
	for bus in AudioSettings.BUSES:
		assert_ne(AudioServer.get_bus_index(bus), -1, bus)
	var fx := AudioServer.get_bus_index("Effects")
	assert_almost_eq(AudioServer.get_bus_volume_db(fx), linear_to_db(0.5), 0.01)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")))
	assert_eq(AudioServer.get_bus_send(fx), &"Master")


func test_ambience_level_is_kept_and_a_limiter_guards_master() -> void:
	var s := AudioSettings.new(_path)
	s.volume["Ambience"] = 0.3
	s.muted["Ambience"] = true
	assert_eq(s.save_settings(), OK)
	var t := AudioSettings.new(_path)
	t.load_settings()
	assert_almost_eq(t.volume["Ambience"], 0.3, 0.0001)
	assert_true(t.muted["Ambience"])
	# an old settings file without the Ambience entry keeps its default
	var f := FileAccess.open(_path, FileAccess.WRITE)
	f.store_string("[audio]\nmusic_volume=0.4\n")
	f.close()
	var u := AudioSettings.new(_path)
	u.load_settings()
	assert_almost_eq(u.volume["Ambience"], AudioSettings.DEFAULT_VOLUME["Ambience"], 0.0001)
	u.apply()
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index("Ambience")), &"Master")
	var master := AudioServer.get_bus_index("Master")
	var limiters := 0
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master, i) is AudioEffectHardLimiter:
			limiters += 1
	assert_eq(limiters, 1, "one limiter, however often the buses are set up")
