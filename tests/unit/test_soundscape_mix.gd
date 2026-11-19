extends GutTest
## M005 the levels of the night's sound (SoundscapeMix, pure): the Copper
## Owl's band full inside and muffled through its walls, fading and dulling
## with distance; the street, the alleys and the river by place and hour; the
## glides that keep every change smooth; the distant sounds' timing.

var layout: DistrictLayout
var club: InteriorPlan


func before_all() -> void:
	layout = RiversideWard.create()
	for p in layout.interiors:
		if (p as InteriorPlan).id == "copper_owl":
			club = p


func _at(distance: float, indoors := false, driving := false, activity := 1.0, dx := 100.0) -> Dictionary:
	return {"in_club": false, "indoors": indoors, "driving": driving, "club_distance": distance, "club_dx": dx,
		"alley": 0.0, "river": 0.0, "activity": activity}


func test_inside_the_club_the_band_is_full_and_unfiltered() -> void:
	var l := _at(0.0)
	l.in_club = true
	var t := SoundscapeMix.targets(l)
	assert_eq(t.music_db, SoundscapeMix.MUSIC_INSIDE_DB)
	assert_eq(t.club_cutoff, SoundscapeMix.OPEN, "no filter inside")
	assert_eq(t.club_pan, 0.0, "all round you")
	assert_lt(t.crowd_db, t.music_db, "the crowd sits under the band")


func test_through_the_walls_the_band_is_quieter_and_muffled() -> void:
	var inside := SoundscapeMix.targets(_at(0.0).merged({"in_club": true}, true))
	var wall := SoundscapeMix.targets(_at(0.0))
	assert_lt(wall.music_db, inside.music_db - 5.0, "quieter outside the walls")
	assert_lte(wall.club_cutoff, SoundscapeMix.WALL_CUTOFF, "the walls take the top off")
	assert_lt(wall.club_cutoff, 1000.0, "the beat and the bass come through; the words do not")
	assert_gt(wall.music_db, SoundscapeMix.AUDIBLE_DB, "but you hear it at the door")


func test_walking_away_it_fades_and_dulls_steadily_until_it_is_gone() -> void:
	var prev := SoundscapeMix.targets(_at(0.0))
	for d in range(20, 1600, 20):
		var t := SoundscapeMix.targets(_at(d))
		assert_lte(t.music_db, prev.music_db, "never louder further away (%d px)" % d)
		assert_lte(t.club_cutoff, prev.club_cutoff + 0.001, "never brighter further away (%d px)" % d)
		if t.music_db > SoundscapeMix.SILENT_DB:
			assert_lt(prev.music_db - t.music_db, 4.0, "no sudden drop (%d px)" % d)
		prev = t
	assert_eq(SoundscapeMix.targets(_at(1500.0)).music_db, SoundscapeMix.SILENT_DB, "gone a few streets away")
	assert_gt(SoundscapeMix.targets(_at(300.0)).music_db, SoundscapeMix.AUDIBLE_DB, "still there across the avenue")


func test_from_another_room_or_a_car_it_is_fainter() -> void:
	var street := SoundscapeMix.targets(_at(150.0))
	var room := SoundscapeMix.targets(_at(150.0, true))
	var car := SoundscapeMix.targets(_at(150.0, false, true))
	assert_lt(room.music_db, street.music_db)
	assert_lte(room.club_cutoff, SoundscapeMix.OTHER_ROOM_CUTOFF)
	assert_lt(car.music_db, street.music_db)
	assert_lt(car.club_cutoff, street.club_cutoff)
	assert_eq(SoundscapeMix.targets(_at(900.0, false, true)).music_db, SoundscapeMix.SILENT_DB,
		"driving away it sinks under the city")


func test_it_comes_from_the_clubs_side() -> void:
	assert_gt(SoundscapeMix.targets(_at(200.0, false, false, 1.0, 300.0)).club_pan, 0.3, "club to the right")
	assert_lt(SoundscapeMix.targets(_at(200.0, false, false, 1.0, -300.0)).club_pan, -0.3, "club to the left")
	assert_lt(absf(SoundscapeMix.targets(_at(0.0, false, false, 1.0, 300.0)).club_pan), 0.2,
		"against the wall it is all round you")


func test_listening_in_the_ward() -> void:
	var owl := SoundscapeMix.listen(layout, club, club.room.get_center(), club, false, 1.0)
	assert_true(owl.in_club)
	assert_eq(owl.club_distance, 0.0)
	var alley_rect: Rect2 = layout.alleys[0].rect
	var in_alley := SoundscapeMix.listen(layout, club, alley_rect.get_center(), null, false, 1.0)
	assert_eq(in_alley.alley, 1.0, "in the alley")
	var water: Rect2 = layout.water[0]
	var quay := SoundscapeMix.listen(layout, club, Vector2(water.position.x - 40.0, 600.0), null, false, 1.0)
	assert_gt(quay.river, 0.9, "at the quay")
	var far := SoundscapeMix.listen(layout, club, Vector2(water.position.x - 2000.0, 600.0), null, false, 1.0)
	assert_eq(far.river, 0.0, "far from the river")


func test_the_street_by_place_and_hour() -> void:
	var evening := SoundscapeMix.targets(_at(2000.0))
	var small_hours := SoundscapeMix.targets(_at(2000.0, false, false, 0.2))
	assert_lt(small_hours.street_db, evening.street_db - 3.0, "quieter before dawn")
	assert_eq(evening.street_cutoff, SoundscapeMix.OPEN, "clear outdoors")
	var indoors := SoundscapeMix.targets(_at(2000.0, true))
	assert_lt(indoors.street_db, evening.street_db)
	assert_eq(indoors.street_cutoff, SoundscapeMix.INDOOR_STREET_CUTOFF, "dull through the windows")
	var alley := _at(2000.0)
	alley.alley = 1.0
	var a := SoundscapeMix.targets(alley)
	assert_gt(a.alley_db, SoundscapeMix.AUDIBLE_DB)
	assert_lt(a.street_db, evening.street_db, "the street recedes in an alley")
	assert_eq(evening.alley_db, SoundscapeMix.SILENT_DB, "no dripping on the avenue")
	assert_eq(evening.river_db, SoundscapeMix.SILENT_DB)


func test_glides_are_smooth_and_get_there() -> void:
	var db := SoundscapeMix.SILENT_DB
	var cutoff := SoundscapeMix.WALL_CUTOFF
	var prev_db := db
	for i in 120:  # two seconds at 60 fps
		db = SoundscapeMix.glide_db(db, SoundscapeMix.MUSIC_INSIDE_DB, 1.0 / 60.0, 0.4)
		cutoff = SoundscapeMix.glide_cutoff(cutoff, SoundscapeMix.OPEN, 1.0 / 60.0, 0.4)
		if i > 0:
			assert_lt(absf(db - prev_db), 3.0, "no jump at frame %d" % i)
		prev_db = db
	assert_almost_eq(db, SoundscapeMix.MUSIC_INSIDE_DB, 0.5)
	assert_gt(cutoff, SoundscapeMix.OPEN * 0.9, "the filter has opened")
	assert_eq(SoundscapeMix.glide_db(SoundscapeMix.SILENT_DB, -20.0, 1.0 / 60.0, 0.4) <= SoundscapeMix.AUDIBLE_DB + 2.0, true,
		"a fade-in starts at the edge of hearing")
	var down := -50.0
	for i in 240:
		down = SoundscapeMix.glide_db(down, SoundscapeMix.SILENT_DB, 1.0 / 60.0, 0.3)
	assert_eq(down, SoundscapeMix.SILENT_DB, "and a fade-out ends in silence")


func test_distant_sounds_come_now_and_then() -> void:
	assert_gt(SoundscapeMix.next_gap("horn", 0.2, 0.0), SoundscapeMix.next_gap("horn", 1.0, 0.0), "fewer horns late at night")
	for kind in ["horn", "foghorn", "clatter"]:
		assert_gt(SoundscapeMix.next_gap(kind, 1.0, 0.0), 10.0, "%s: not a constant trigger" % kind)
	var street := _at(800.0)
	assert_true(SoundscapeMix.can_hear("horn", street))
	assert_false(SoundscapeMix.can_hear("foghorn", street), "the tug is heard by the river")
	assert_false(SoundscapeMix.can_hear("clatter", street), "the lids are in the alleys")
	street.river = 0.6
	street.alley = 0.8
	assert_true(SoundscapeMix.can_hear("foghorn", street))
	assert_true(SoundscapeMix.can_hear("clatter", street))
	street.in_club = true
	assert_false(SoundscapeMix.can_hear("horn", street), "not over the band")


## M011: the Copper Owl's back rooms (the card room, the gaming room): their own
## bed, prominent inside, silent anywhere else; the band muffled through the
## walls there, fainter in the gaming room (a room further off) than in the
## card room; the room's own sounds only in the back rooms.
func test_the_back_rooms() -> void:
	var rooms := {}
	for p in layout.interiors:
		rooms[(p as InteriorPlan).id] = p
	var card := SoundscapeMix.targets(SoundscapeMix.listen(layout, club, RiversideInteriors.TABLE + Vector2(0, 54), rooms.back_room, false, 1.0))
	var gaming := SoundscapeMix.targets(SoundscapeMix.listen(layout, club, RiversideInteriors.ROULETTE_SPOT, rooms.gaming_room, false, 1.0))
	var in_club := SoundscapeMix.targets(SoundscapeMix.listen(layout, club, Vector2(2290, 300), club, false, 1.0))
	var street := SoundscapeMix.targets(SoundscapeMix.listen(layout, club, Vector2(2290, 600), null, false, 1.0))
	var shop := SoundscapeMix.targets(SoundscapeMix.listen(layout, club, Vector2(990, 366), rooms.barber_shop, false, 1.0))
	for t in [card, gaming]:
		assert_eq(t.gaming_db, SoundscapeMix.GAMING_DB, "the back rooms' bed")
		assert_gt(t.gaming_db, t.music_db + 6.0, "the room is louder than the band through the wall")
		assert_lte(t.club_cutoff, SoundscapeMix.OTHER_ROOM_CUTOFF, "the band muffled")
		assert_gt(t.music_db, SoundscapeMix.SILENT_DB, "but there")
	assert_lt(gaming.music_db, card.music_db, "fainter a room further off")
	for t in [in_club, street, shop]:
		assert_eq(t.gaming_db, SoundscapeMix.SILENT_DB, "the back rooms' bed nowhere else")
	assert_eq(in_club.club_cutoff, SoundscapeMix.OPEN, "back in the club: the band full again")
	var l_card := SoundscapeMix.listen(layout, club, RiversideInteriors.TABLE, rooms.back_room, false, 1.0)
	var l_club := SoundscapeMix.listen(layout, club, Vector2(2290, 300), club, false, 1.0)
	assert_true(SoundscapeMix.can_hear("room", l_card))
	assert_false(SoundscapeMix.can_hear("room", l_club))
	assert_false(SoundscapeMix.can_hear("room", SoundscapeMix.listen(layout, club, Vector2(2290, 600), null, false, 1.0)))
	var gaps := []
	for i in 20:
		gaps.append(SoundscapeMix.next_gap("room", 1.0, i / 20.0))
	assert_gt(gaps.min(), 2.5, "not one on top of the other")
	assert_lt(gaps.max(), 9.0, "but the room never goes dead")
