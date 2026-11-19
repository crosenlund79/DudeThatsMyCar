class_name SlotReels
extends RefCounted
## How the three reels of a pull look (pure presentation maths, no scene):
## after the lever goes down they jerk into motion together, the symbols
## running down past the window, and stop one after the other - left, middle,
## right - each with a little clunk past its stop and back, on exactly the
## stop SlotMachine drew. Each reel's run is worked out backwards from that
## stop, so the line in the window is always the drawn result.
##
## A reel's position is in stops along its strip: the symbol on the line is
## the strip's at the position rounded; the one above it is the next.
## M013: a held reel (`held`) does not move at all - not a jerk, not a clunk;
## the others run and stop in their order as before.

## Stops a second while running (nominal).
const SPEED := 14.0
## The clunk past the stop and back (stops, seconds).
const CLUNK := 0.22
const CLUNK_TIME := 0.22

var start: Array[float] = []
var target: Array[int] = []
var times: Array[float] = []
var lengths: Array[int] = []
## When the reels start turning (after the lever comes down).
var begin := 0.25
var held: Array[bool] = [false, false, false]
var _final: Array[float] = []
var _speed: Array[float] = []


func _init(p_start: Array, p_target: Array, p_times: PackedFloat32Array, p_lengths: Array, p_begin: float = 0.25,
		p_held: Array = [false, false, false]) -> void:
	begin = p_begin
	for i in 3:
		held[i] = bool(p_held[i]) if i < p_held.size() else false
		start.append(float(p_start[i]))
		target.append(int(p_target[i]))
		times.append(maxf(float(p_times[i]), begin + 0.3))
		lengths.append(int(p_lengths[i]))
		if held[i]:
			start[i] = float(target[i])  # it stands on its stop the whole time
			times[i] = 0.0
			_final.append(start[i])
			_speed.append(0.0)
			continue
		var run := times[i] - begin
		var fin := float(target[i])
		while fin < start[i] + SPEED * run:
			fin += lengths[i]
		_final.append(fin)
		_speed.append((fin - start[i]) / run)


func position(reel: int, t: float) -> float:
	if held[reel]:
		return start[reel]
	if t <= begin:
		return start[reel]
	if t < times[reel]:
		return start[reel] + _speed[reel] * (t - begin)
	var x := (t - times[reel]) / CLUNK_TIME
	if x < 1.0:
		return _final[reel] + CLUNK * sin(x * PI) * (1.0 - x)
	return _final[reel]


func stopped(reel: int, t: float) -> bool:
	return t >= times[reel]


func done(t: float) -> bool:
	var last := 0.0
	for i in 3:
		if not held[i]:
			last = maxf(last, times[i])
	return t >= last + CLUNK_TIME


## The stop on the line of a reel at time t.
func on_line(reel: int, t: float) -> int:
	return posmod(roundi(position(reel, t)), lengths[reel])
