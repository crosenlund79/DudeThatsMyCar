extends GutTest
## M006 the Bird's act (StageAct, BirdPerformance.pose_at; pure): only a
## singing Bird can be interrupted, the song starts again once after a talk,
## and her moves follow the slow ballad.


func test_one_interruption_one_resumption() -> void:
	var s := StageAct.new()
	assert_true(s.singing())
	assert_true(s.interrupt(), "Danny stops her song")
	assert_false(s.interrupt(), "she has stopped already: no second scratch")
	assert_false(s.update(10.0), "she waits while they talk")
	s.release()
	assert_false(s.update(StageAct.RESUME_DELAY * 0.5), "a moment after he walks away...")
	assert_true(s.update(StageAct.RESUME_DELAY), "...the band counts her back in")
	assert_false(s.update(1.0), "once")
	assert_true(s.singing())
	assert_eq(s.interruptions, 1)


func test_talking_between_songs_holds_her() -> void:
	var s := StageAct.new()
	s.interrupt()
	s.release()
	s.update(1.0)
	s.hold()
	assert_false(s.update(StageAct.RESUME_DELAY * 2.0), "back at her side before the band starts: she waits")
	assert_false(s.interrupt(), "no scratch: she isn't singing")
	s.release()
	assert_true(s.update(StageAct.RESUME_DELAY + 0.01))


func test_a_new_night_she_sings() -> void:
	var s := StageAct.new()
	s.interrupt()
	s.reset()
	assert_true(s.update(0.01), "the song starts when the club opens")
	assert_eq(s.interruptions, 0)


func test_her_moves_follow_the_ballad() -> void:
	var frames := {}
	var max_sway := 0.0
	var t := 0.0
	while t < 40.0:
		var p := BirdPerformance.pose_at(t)
		frames[p.frame] = true
		max_sway = maxf(max_sway, absf(p.sway))
		t += 0.05
	assert_eq(frames.size(), 5, "every gesture in turn")
	assert_lt(max_sway, 0.12, "a subtle sway, not a dance")
	var beat := BirdPerformance.BEAT
	assert_almost_eq(beat, 60.0 / 54.5, 0.01, "the song's tempo")
	assert_eq(BirdPerformance.pose_at(0.1).frame, BirdPerformance.pose_at(beat * 4.0 - 0.1).frame, "a gesture lasts four beats")
	assert_almost_eq(BirdPerformance.pose_at(beat * 0.5).sway, BirdPerformance.SWAY, 0.001, "one sway over two beats")
