extends GutTest
## The handgun's state: drawn on the first click, one shot per click with a
## short interval, seven rounds then a reload by itself, a slightly early
## click still fires, back under the coat after a while.

const DT := 1.0 / 60.0

var rules: GunRules


func before_each() -> void:
	rules = load("res://src/weapons/default_pistol.tres")


func _run(g: Gun, seconds: float) -> PackedStringArray:
	var all := PackedStringArray()
	for i in int(round(seconds / DT)):
		all.append_array(g.step(DT))
	return all


func _shots(events: PackedStringArray) -> int:
	return Array(events).count("fired")


func test_the_first_click_draws_and_then_fires() -> void:
	var g := Gun.new(rules)
	assert_false(g.is_drawn())
	g.trigger()
	assert_true(g.is_drawn(), "out from under the coat")
	var first := g.step(DT)
	assert_false(first.has("fired"), "not before it is drawn")
	var events := _run(g, rules.draw_time + 0.05)
	assert_eq(_shots(events), 1, "the click fires once the gun is out")
	assert_eq(g.ammo, rules.magazine - 1)


func test_one_shot_per_click() -> void:
	var g := Gun.new(rules)
	g.trigger()
	_run(g, 0.5)
	var events := _run(g, 2.0)
	assert_eq(_shots(events), 0, "holding nothing fires nothing")
	g.trigger()
	assert_eq(_shots(_run(g, 0.5)), 1)


func test_a_click_during_the_interval_fires_when_ready() -> void:
	var g := Gun.new(rules)
	g.trigger()
	_run(g, rules.draw_time + 0.02)
	g.trigger()  # straight after the first shot
	var events := _run(g, rules.fire_interval + 0.05)
	assert_eq(_shots(events), 1, "buffered, then fired after the interval")


func test_an_old_click_is_forgotten() -> void:
	var g := Gun.new(rules)
	g.trigger()
	_run(g, 0.5)
	g.state = Gun.State.RELOADING  # pretend busy
	g._timer = 0.6
	g.trigger()  # ignored while reloading
	assert_eq(_shots(_run(g, 1.0)), 0)


func test_seven_rounds_then_it_reloads_by_itself() -> void:
	var g := Gun.new(rules)
	var shots := 0
	for i in rules.magazine:
		g.trigger()
		shots += _shots(_run(g, 0.4))
	assert_eq(shots, rules.magazine)
	assert_eq(g.ammo, 0)
	assert_true(g.is_reloading())
	g.trigger()
	assert_eq(_shots(_run(g, rules.reload_time * 0.5)), 0, "no shot while reloading")
	var events := _run(g, rules.reload_time)
	assert_true(events.has("reloaded"))
	assert_eq(g.ammo, rules.magazine)


func test_back_under_the_coat_after_a_quiet_while() -> void:
	var g := Gun.new(rules)
	g.trigger()
	_run(g, 0.5)
	var events := _run(g, rules.holster_after + 0.1)
	assert_true(events.has("holstered"))
	assert_false(g.is_drawn())
	assert_eq(g.ammo, rules.magazine - 1, "the rounds stay counted")


func test_holster_puts_it_away_at_once() -> void:
	var g := Gun.new(rules)
	g.trigger()
	g.holster()
	assert_false(g.is_drawn())
	assert_eq(_shots(_run(g, 1.0)), 0, "the pending click is dropped")


## Fires one round per trigger pull until n rounds are out (draws first).
func _empty_magazine(g: Gun) -> void:
	for i in 30:
		if g.ammo == 0 or g.is_reloading():
			break
		g.trigger()
		_run(g, rules.fire_interval + DT)


func test_reloads_come_out_of_the_spare_rounds() -> void:
	var g := Gun.new(rules)
	assert_eq(g.spare, rules.spare_rounds, "M003: the pistol starts with a couple of spare magazines")
	_empty_magazine(g)
	_run(g, rules.reload_time + DT)
	assert_eq(g.ammo, rules.magazine)
	assert_eq(g.spare, rules.spare_rounds - rules.magazine)


func test_out_of_rounds_it_only_clicks() -> void:
	var g := Gun.new(rules)
	g.spare = 3
	_empty_magazine(g)
	_run(g, rules.reload_time + DT)
	assert_eq(g.ammo, 3, "a short reload with what was left")
	assert_eq(g.spare, 0)
	_empty_magazine(g)
	_run(g, rules.reload_time + DT)
	assert_true(g.is_dry())
	assert_false(g.is_reloading(), "nothing to reload with")
	g.trigger()
	var events := _run(g, 0.2)
	assert_true(events.has("empty"), "click")
	assert_eq(_shots(events), 0)
	g.add_spare(14)
	assert_true(g.is_reloading(), "new rounds go straight in")
	_run(g, rules.reload_time + DT)
	assert_eq(g.ammo, rules.magazine)
	assert_eq(g.spare, 14 - rules.magazine)


func test_unlimited_spare_rounds_as_in_m002() -> void:
	var r := rules.duplicate() as GunRules
	r.spare_rounds = -1
	var g := Gun.new(r)
	for k in 3:
		_empty_magazine(g)
		_run(g, r.reload_time + DT)
	assert_eq(g.ammo, r.magazine)
	assert_eq(g.spare, -1)
