extends GutTest
## M005 the opening as data (OpeningScript, pure): the monologue's subtitles
## in order and inside the recording, the camera's path from the river past
## the Copper Owl to Danny's flat, smooth all the way.

var layout: DistrictLayout
var club: InteriorPlan


func before_all() -> void:
	layout = RiversideWard.create()
	for p in layout.interiors:
		if (p as InteriorPlan).id == "copper_owl":
			club = p


func test_the_subtitles_follow_the_recording() -> void:
	var prev_end := 0.0
	for c in OpeningScript.CUES:
		assert_gte(float(c[0]), prev_end, "in order, never overlapping: %s" % c[2])
		assert_gt(float(c[1]), float(c[0]))
		assert_lte(float(c[1]), OpeningScript.RECORDING_LENGTH)
		prev_end = c[1]
	assert_eq(OpeningScript.cue_at(0.5), "Chicago. 1932.")
	assert_eq(OpeningScript.cue_at(10.0), "Name's Danny Mercer. They call me Dimes.")
	assert_eq(OpeningScript.cue_at(13.0), "I work for a fella named Rourke.")
	assert_eq(OpeningScript.cue_at(22.0), "Well... better get to work.")
	assert_eq(OpeningScript.cue_at(2.6), "", "a breath between lines")
	assert_eq(OpeningScript.cue_at(30.0), "", "nothing after the end")
	var words := []
	for c in OpeningScript.CUES:
		words.append(c[2])
	assert_eq(" ".join(words), "Chicago. 1932. Everybody's broke. Nobody's honest. And somehow everybody's got money for booze. " +
		"Name's Danny Mercer. They call me Dimes. I work for a fella named Rourke. He gets his cut. I get what's left. " +
		"Funny thing is, there ain't usually much left. Well... better get to work.", "the verified transcript")


func test_the_camera_drifts_from_the_river_to_dannys_flat() -> void:
	var home := layout.spawn
	var keys := OpeningScript.shots(layout, club, home, OpeningScript.RECORDING_LENGTH)
	var start := OpeningScript.rig_at(keys, 0.0)
	var water: Rect2 = layout.water[0]
	assert_lt(water.position.x - start.pos.x, 400.0, "it begins by the river")
	var by_the_club := false
	var prev: Dictionary = start
	var t := 0.0
	while t < OpeningScript.RECORDING_LENGTH + 1.0:
		var r := OpeningScript.rig_at(keys, t)
		assert_lt((r.pos as Vector2).distance_to(prev.pos), 12.0, "no jump at %.2f s" % t)
		assert_lt(absf(float(r.zoom) - float(prev.zoom)), 0.01)
		assert_true(layout.bounds.has_point(r.pos), "inside the ward at %.2f s" % t)
		if SoundscapeMix.rect_distance(club.building_rect, r.pos) < 150.0:
			by_the_club = true
		prev = r
		t += 1.0 / 60.0
	assert_true(by_the_club, "past the Copper Owl's door (the singer through the walls)")
	var end := OpeningScript.rig_at(keys, OpeningScript.RECORDING_LENGTH)
	assert_eq(end.pos, home, "it ends on Danny")
	assert_almost_eq(float(end.zoom), CityCamera.new().foot_zoom, 0.001, "at the usual distance")


func test_the_shots_stretch_to_the_recording() -> void:
	var short := OpeningScript.shots(layout, club, layout.spawn, 10.0)
	assert_almost_eq(float(short[short.size() - 1].t), 10.0, 0.001)
	var long := OpeningScript.shots(layout, club, layout.spawn, 40.0)
	assert_almost_eq(float(long[long.size() - 1].t), 40.0, 0.001)
