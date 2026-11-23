class_name NightCycle
extends RefCounted
## M014 (from main): the night in the game - the clock moving on (and the
## ward's businesses, the incidents, the weather and its thunder, the jobs with
## it), the reminders to go home, the tables closing at the hour, sitting with
## Space held to let the time pass (M010) without skipping a moment that must
## not be missed, and sleeping through the day into the next evening (M003):
## everything that starts every night afresh, in the order it always did.

## M010: how fast time passes while he sits with Space held (game minutes per game minute).
const FAST_TIME := 20.0
## M015: at the card table the night goes at a quarter of its pace while the
## hand plays, and stands still while a beat waits for Space (the game still
## breaks up at four).
const POKER_TIME := 0.25

var game: Game
## Reminders given tonight: 0 none, 1 "get home", 2 "dawn".
var warned := 0
## Game minutes of moments fast time must not skip (the cafe job's blast, ...).
var moments: Array[float] = []


func _init(p_game: Game) -> void:
	game = p_game


## The clock (`running`: not under the menu, not during the opening), then the
## hour's consequences and the clock on the HUD.
func update(delta: float, running: bool) -> void:
	var clock := game.clock
	var hud := game.hud
	if running:
		var before := clock.minute
		clock.advance(delta * time_scale())
		game.rackets.town.advance(clock.minute - before)  # the club serves its customers as the night goes on
		game.incident_director.advance()
		var weather := game.weather
		weather.advance(clock.minute)  # M010
		var claps := weather.thunder_between(before, clock.minute)  # M012: thunder in a downpour
		if not claps.is_empty():  # one at a time, however fast the night runs
			game.soundscape.thunder(claps[-1].near)
			game.weather_view.lightning(claps[-1].near)
		game.missions.clock(clock.minute, delta)  # M009-M012: too late is too late; the truck; the cafe
	if clock.minute >= float(game.night_rules.home_minute):
		game.back_rooms.closing_time()  # M010: the card game breaks up at the hour to go home; M013: the wheel's last round
	if clock.is_dawn() and warned < 2:
		warned = 2
		hud.show_notice("Dawn's breaking. Get home to bed before the city wakes up.")
	elif clock.is_late() and warned < 1:
		warned = 1
		hud.show_notice("It's getting late. Time to head home to bed.")
	hud.set_clock(game.rackets.night, clock.text(), clock.is_late())


## M010: sitting with Space held, the night passes FAST_TIME times as fast -
## but never past the next moment that must not be missed (it slows to normal
## a couple of minutes before). M015: at the card table, POKER_TIME (0 while
## a beat waits for Space).
func time_scale() -> float:
	if game.back_rooms != null and game.back_rooms.playing_poker():
		return 0.0 if game.hud.poker_view.pacing.waiting() else POKER_TIME
	var player := game.player
	if player.seat.is_empty() or not player.passing_time or game.films.of("cafe") != null:
		return 1.0
	if next_moment() - game.clock.minute < 2.0:
		return 1.0
	return FAST_TIME


## The game minute of the next moment fast time must not skip (INF: none).
func next_moment() -> float:
	var next := INF
	for m in moments:
		if m >= game.clock.minute - 0.01:
			next = minf(next, m)
	return next


## Sleeps through the day: the next evening begins at home with everything
## you carry (money, bottles, rounds); the streets, the cars and the copper
## are back as they are at the start of every night, and tonight's deals reset.
func sleep() -> void:
	var r := game.rackets
	var walker := game.walker
	var night_rules := game.night_rules
	game.dialogue.end()
	game.club.new_night()  # the Bird is singing when the club opens
	game.casualties.new_night()  # back from the Doc's, patched up (and they remember)
	game.fleet.new_night()  # the cars are back with their owners, nothing in a boot (M009)
	for v in game.interiors.views:
		v.reset_people()
	game.rival.reset()
	walker.condition.rest()  # grazes heal overnight; wounds wait for the Doc
	r.end_night()
	game.clock.reset()
	game.incidents.begin_night(r.night, float(night_rules.start_minute), float(night_rules.dawn_minute))
	game.weather.begin_night(r.night, float(night_rules.start_minute))
	game.weather.force(game.weather_override())
	r.money += game.back_rooms.begin_night(r.night)  # M010-M013: fresh money at the tables, the wheel's cover off
	moments.clear()
	game.missions.new_night()  # the street cleared by morning (M010); the Bird back at her microphone (M012)
	warned = 0
	game.police.cancel_report()
	game.fleet.back_to_places()
	game.police.new_night()
	game.districts.new_night()  # the street life as every evening; a new man on every beat
	if walker.gun != null:
		walker.gun.holster()
	var layout := game.layout
	walker.place(layout.spawn, layout.spawn_facing)
	game.interiors.update_player(walker.global_position)
	game.interiors.snap()
	game.camera.snap_to(walker)
	game.hud.set_purse(r.money, r.bottles, r.held)
	var news := ""
	if r.collected > 0:
		news = "Rourke's boys were waiting on the stairs.\nThey took %s off you." % Rackets.dollars(r.collected)
	game.hud.wake_up(r.night, game.clock.text(), news)
	game.save()
