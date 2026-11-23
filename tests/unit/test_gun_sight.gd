extends GutTest
## M015 (GunSight, PedestrianBrain): a gun in Danny's hand makes passers-by
## wary (they walk briskly away along their route, an eye on him) and run if
## he comes too close with it - farther for a Thompson; a copper warns, then
## comes for him once his patience (shorter for a Thompson) runs out; the
## people who keep a place of business have their words for it.


func test_passers_by() -> void:
	assert_eq(GunSight.passer(500.0, GunSight.HANDGUN), "")
	assert_eq(GunSight.passer(200.0, GunSight.HANDGUN), "wary")
	assert_eq(GunSight.passer(90.0, GunSight.HANDGUN), "flee")
	assert_eq(GunSight.passer(300.0, GunSight.THOMPSON), "wary", "a Thompson is noticed farther off")
	assert_eq(GunSight.passer(180.0, GunSight.THOMPSON), "flee", "and frightens more")
	assert_eq(GunSight.passer(10.0, GunSight.NONE), "", "nothing in his hand, nothing to fear")


func test_a_coppers_patience() -> void:
	assert_eq(GunSight.copper(0.0, GunSight.HANDGUN), "warn")
	assert_eq(GunSight.copper(3.0, GunSight.HANDGUN), "watch")
	assert_eq(GunSight.copper(6.0, GunSight.HANDGUN), "come")
	assert_eq(GunSight.copper(3.0, GunSight.THOMPSON), "come", "less patience with a Tommy gun")
	assert_eq(GunSight.copper(9.0, GunSight.NONE), "")


func test_their_words() -> void:
	for who in GunSight.SHY:
		assert_ne(GunSight.line(who, 1), "", who)
		assert_ne(GunSight.line(who, 2), GunSight.line(who, 1), who + ": a Thompson is something else")
	assert_eq(GunSight.line("eddie", 1), "", "Eddie sells them")
	assert_eq(GunSight.line("augie", 0), "")


func test_a_passer_by_keeps_away_and_runs() -> void:
	var route := PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(800, 0)])
	var b := PedestrianBrain.new(route, 5)
	b.nearest_on_route(Vector2(400, 0))
	var me := Vector2(400, 0)
	var out := b.update(0.1, me, [], {"pos": Vector2(250, 0), "level": GunSight.HANDGUN})
	assert_eq(b.state, PedestrianBrain.State.WARY)
	assert_gt((out.dir as Vector2).dot(Vector2.RIGHT), 0.5, "away from him, along the sidewalk")
	assert_eq(out.look, Vector2(250, 0), "an eye on him")
	assert_eq(out.speed, PedestrianBrain.BRISK)
	out = b.update(0.1, me, [], {"pos": Vector2(330, 0), "level": GunSight.HANDGUN})
	assert_eq(b.state, PedestrianBrain.State.FLEE, "too close: they run")
	assert_eq(out.speed, PedestrianBrain.RUN)
	for i in 40:
		out = b.update(0.1, me + Vector2(300, 0), [], {})
	assert_ne(b.state, PedestrianBrain.State.FLEE, "and calm down again")
	var c := PedestrianBrain.new(route, 6)
	c.nearest_on_route(Vector2(400, 0))
	c.update(0.1, me, [], {"pos": Vector2(250, 0), "level": GunSight.HANDGUN})
	c.update(0.1, me, [], {"pos": Vector2(250, 0), "level": GunSight.NONE})
	assert_eq(c.state, PedestrianBrain.State.RETURN, "the gun put away: back to their way")
