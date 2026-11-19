class_name RouletteSpin
extends RefCounted
## How one spin of the wheel looks (pure presentation maths, no scene): the
## wheel head turning clockwise and slowing, the ball sent round the track
## the other way, slowing, dropping off it, bouncing over the frets and coming
## to rest - in the pocket of the number Roulette already decided. The number
## is given; nothing here can change it: the ball's last stretch is worked out
## backwards from that pocket, so where it ends and what the rules said are
## the same thing.
##
## Angles in radians, clockwise on screen (Godot's), 0 pointing right; the
## wheel head's zero is at its top (-PI/2) when it is not turned, the pockets
## clockwise from it in Roulette.WHEEL's order. Radii as a fraction of the
## bowl's radius.

## The ball on its track, and resting in a pocket.
const TRACK := 0.88
const POCKET := 0.593
## The wheel head's size within the bowl.
const ROTOR := 0.78
const ROTOR_SPEED := 2.2
const ROTOR_EASE := 8.0
const BALL_SPEED := 11.0
const BALL_EASE := 3.0
## When the ball leaves the track (a fraction of the spin).
const DROP := 0.62

var result := 0
var duration := 6.5
var rotor_start := 0.0
var ball_start := 0.0
var _t_drop := 0.0
var _rel_drop := 0.0
var _delta := 0.0
var _m := 1.0


func _init(p_result: int, p_rotor_start: float, p_ball_start: float, p_duration: float = 6.5) -> void:
	result = p_result
	rotor_start = p_rotor_start
	ball_start = p_ball_start
	duration = maxf(p_duration, 1.0)
	_t_drop = duration * DROP
	_rel_drop = _ball_free(_t_drop) - rotor_angle(_t_drop)
	# from where the ball leaves the track, at least one more lap round the head to its pocket
	var d := fposmod(_rel_drop - pocket_angle(result), TAU)
	_delta = -(d + TAU)
	# start that last stretch at the speed the ball already has against the head
	var v0 := _ball_speed(_t_drop) - _rotor_speed(_t_drop)
	_m = clampf(v0 * (duration - _t_drop) / _delta, 0.0, 3.0)


## Where pocket `number` is on the wheel head (head not turned).
static func pocket_angle(number: int) -> float:
	return -PI / 2.0 + TAU * Roulette.pocket_index(number) / 37.0


## The number in the pocket at angle `rel` on the head (relative to it).
static func pocket_at(rel: float) -> int:
	var k := posmod(roundi((rel + PI / 2.0) / (TAU / 37.0)), 37)
	return Roulette.WHEEL[k]


func rotor_angle(t: float) -> float:
	return rotor_start + ROTOR_SPEED * ROTOR_EASE * (1.0 - exp(-maxf(t, 0.0) / ROTOR_EASE))


func _rotor_speed(t: float) -> float:
	return ROTOR_SPEED * exp(-t / ROTOR_EASE)


func _ball_free(t: float) -> float:
	return ball_start - BALL_SPEED * BALL_EASE * (1.0 - exp(-maxf(t, 0.0) / BALL_EASE))


func _ball_speed(t: float) -> float:
	return -BALL_SPEED * exp(-t / BALL_EASE)


## The ball's angle on the wheel at time t (seconds since the spin began).
func ball_angle(t: float) -> float:
	if t <= _t_drop:
		return _ball_free(t)
	if t >= duration:
		return rotor_angle(t) + _rel_drop + _delta
	var s := (t - _t_drop) / (duration - _t_drop)
	var h := _m * s + (3.0 - 2.0 * _m) * s * s + (_m - 2.0) * s * s * s
	return rotor_angle(t) + _rel_drop + _delta * h + _jitter(s)


## The bounces over the frets: a little back and forth that dies away to nothing.
func _jitter(s: float) -> float:
	var on := clampf((s - 0.08) / 0.12, 0.0, 1.0)
	return 0.09 * sin(s * 31.0) * pow(1.0 - s, 2.0) * on


## The ball's distance from the middle (a fraction of the bowl's radius).
func ball_radius(t: float) -> float:
	var start := _t_drop * 0.85
	if t <= start:
		return TRACK
	if t >= duration:
		return POCKET
	var s := (t - start) / (duration - start)
	var fall := smoothstep(0.0, 0.45, s)
	var bounce := 0.06 * absf(sin(s * 24.0)) * pow(1.0 - s, 2.0) * clampf((s - 0.25) * 6.0, 0.0, 1.0)
	return lerpf(TRACK, POCKET, fall) + bounce


func done(t: float) -> bool:
	return t >= duration


## The number the ball sits on at time t.
func pocket_under(t: float) -> int:
	return pocket_at(ball_angle(t) - rotor_angle(t))
