class_name RouletteMotion
extends RefCounted
## M013: how the wheel looks, all night (pure presentation maths, no scene;
## replaces M011's one-spin RouletteSpin). The head always turns: the
## croupier pushes it at the start of each round and it slows between, never
## quite stopping. The ball is picked out of its pocket and held on the track,
## sent round the other way, and circles - slowing, but never below a pace
## that keeps it on the track however long the call is put off - until the
## croupier calls no more bets. Then it drops off the track, over the frets,
## into the pocket of the number the table has just drawn: its last stretch is
## worked back from that pocket, so where it ends and what the rules said are
## one thing, and nothing here can change it. It rides round in its pocket
## with the head until the next round.
##
## Angles in radians, clockwise on screen (Godot's), 0 pointing right; the
## head's zero is at its top (-PI/2) when the head is not turned, the pockets
## clockwise from it in Roulette.WHEEL's order. Radii as a fraction of the
## bowl's radius. advance() integrates frame by frame (continuous whatever
## the frame rate; long frames are cut into short steps).

## The ball on its track, and resting in a pocket; the head's size in the bowl.
const TRACK := 0.88
const POCKET := 0.593
const ROTOR := 0.78
## The head: its speed after a push (rad/s, clockwise), how slowly it slows
## (s), the least it turns between pushes, how long a push takes (s).
const ROTOR_KICK := 2.2
const ROTOR_EASE := 12.0
const ROTOR_IDLE := 0.22
const KICK_TIME := 0.9
## The ball: its speed sent round (rad/s, anticlockwise), how it slows (s),
## the pace it keeps while bets are open, how long lifting it out takes (s).
const BALL_LAUNCH := 11.0
const BALL_EASE := 4.5
const BALL_FLOOR := 5.5
const LIFT_TIME := 0.7
## Where the croupier holds the ball on the track before sending it round (his side of the bowl).
const HAND := PI * 0.75

enum Ball { POCKET, LIFT, HELD, TRACK, DROP }

var rotor := 0.0
var rotor_speed := ROTOR_IDLE
var _kick_left := 0.0
var ball := Ball.POCKET
## The ball's angle (absolute) and distance from the middle.
var ball_angle := -PI / 2.0
var ball_r := POCKET
## On the track: its speed (rad/s, negative: anticlockwise). In a pocket: its angle on the head.
var ball_speed := 0.0
var ball_rel := -PI / 2.0
## The pocket it is dropping into / sits in (-1: none yet tonight).
var number := -1
var _t := 0.0
var _from_angle := 0.0
var _drop_rel := 0.0
var _drop_delta := 0.0
var _drop_m := 1.0
var drop_time := 3.5


## Where pocket `n` is on the head (head not turned).
static func pocket_angle(n: int) -> float:
	return -PI / 2.0 + TAU * Roulette.pocket_index(n) / 37.0


## The number in the pocket at angle `rel` on the head (relative to it).
static func pocket_at(rel: float) -> int:
	var k := posmod(roundi((rel + PI / 2.0) / (TAU / 37.0)), 37)
	return Roulette.WHEEL[k]


## The croupier gives the head a push (it speeds up over KICK_TIME).
func kick() -> void:
	_kick_left = KICK_TIME


## The croupier picks the ball out of its pocket and holds it on the track.
func lift() -> void:
	if ball != Ball.POCKET:
		return
	ball = Ball.LIFT
	_t = 0.0
	_from_angle = ball_angle


## The ball is sent round the track.
func launch() -> void:
	if ball == Ball.POCKET:
		lift()
	ball = Ball.TRACK
	ball_r = TRACK
	ball_speed = -BALL_LAUNCH


## No more bets: the ball leaves the track and comes to rest in `n`'s pocket
## `seconds` from now.
func drop(n: int, seconds: float) -> void:
	if ball != Ball.TRACK:
		launch()
	number = n
	drop_time = maxf(seconds, 1.0)
	ball = Ball.DROP
	_t = 0.0
	_drop_rel = ball_angle - rotor
	# at least one more lap round the head to its pocket, in the way it is going
	var d := fposmod(_drop_rel - pocket_angle(n), TAU)
	_drop_delta = -(d + TAU)
	var v0 := ball_speed - rotor_speed
	_drop_m = clampf(v0 * drop_time / _drop_delta, 0.0, 3.0)


## The number under the ball now (meaningful in its pocket).
func pocket_under() -> int:
	return pocket_at(ball_angle - rotor)


func resting() -> bool:
	return ball == Ball.POCKET


func advance(dt: float) -> void:
	var left := maxf(dt, 0.0)
	while left > 0.0:
		var step := minf(left, 1.0 / 30.0)
		left -= step
		_step(step)


func _step(dt: float) -> void:
	# the head
	if _kick_left > 0.0:
		_kick_left -= dt
		rotor_speed = move_toward(rotor_speed, ROTOR_KICK, ROTOR_KICK / KICK_TIME * dt)
	else:
		rotor_speed = maxf(ROTOR_IDLE, rotor_speed * exp(-dt / ROTOR_EASE))
	rotor += rotor_speed * dt
	# the ball
	_t += dt
	match ball:
		Ball.POCKET:
			ball_angle = rotor + ball_rel
			ball_r = POCKET
		Ball.LIFT:
			var s := smoothstep(0.0, 1.0, minf(_t / LIFT_TIME, 1.0))
			ball_angle = lerp_angle(_from_angle, HAND, s)
			ball_r = lerpf(POCKET, TRACK, s) + 0.05 * sin(s * PI)
			if _t >= LIFT_TIME:
				ball = Ball.HELD
		Ball.HELD:
			ball_angle = HAND
			ball_r = TRACK
		Ball.TRACK:
			ball_speed = -maxf(BALL_FLOOR, absf(ball_speed) * exp(-dt / BALL_EASE))
			ball_angle += ball_speed * dt
			ball_r = TRACK
		Ball.DROP:
			var s := minf(_t / drop_time, 1.0)
			var h := _drop_m * s + (3.0 - 2.0 * _drop_m) * s * s + (_drop_m - 2.0) * s * s * s
			ball_angle = rotor + _drop_rel + _drop_delta * h + _jitter(s)
			ball_r = _drop_radius(s)
			if _t >= drop_time:
				ball = Ball.POCKET
				ball_rel = pocket_angle(number)
				ball_angle = rotor + ball_rel
				ball_r = POCKET


## The bounces over the frets: a little back and forth that dies away to nothing.
func _jitter(s: float) -> float:
	var on := clampf((s - 0.08) / 0.12, 0.0, 1.0)
	return 0.09 * sin(s * 31.0) * pow(1.0 - s, 2.0) * on


func _drop_radius(s: float) -> float:
	var fall := smoothstep(0.0, 0.45, s)
	var bounce := 0.06 * absf(sin(s * 24.0)) * pow(1.0 - s, 2.0) * clampf((s - 0.25) * 6.0, 0.0, 1.0)
	return lerpf(TRACK, POCKET, fall) + bounce
