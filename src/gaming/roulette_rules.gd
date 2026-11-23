class_name RouletteRules
extends Resource
## The gaming room's wheel table (default_roulette.tres): the chips the
## croupier sells, the table's limits (in cents) and the round's timing.
## PROVISIONAL, to be tuned by playing. M015: the limits about ten times
## M011's (a $5 chip; $5 on a number, $10 on any other inside bet, $50 on an
## outside bet, $100 a spin) and a quicker round, with the betting timer's
## presets (PACES) - each table can be given its own resource.

## The chip denominations, smallest first.
@export var chips: Array[int] = [5, 10, 25, 100, 500]
## Each bet must be at least this much when the wheel is spun.
@export var min_bet := 5
## The most on one bet: a single number, any other inside bet, an outside bet.
@export var max_straight := 500
@export var max_inside := 1000
@export var max_outside := 5000
## The most on the whole layout in one spin.
@export var max_total := 10000
## M013: Leo's rounds (seconds), at the Normal pace: bets open while the head
## turns, then with the ball going round; the call ("no more bets") comes
## ball_seconds after it is sent; the ball drops for drop_seconds; the number
## stands for result_seconds. M015: 5 + 5 + 3.6 + 4 (M013's 9 + 7 + 3.6 + 5.5
## is now the Relaxed pace).
@export var open_seconds := 5.0
@export var ball_seconds := 5.0
@export var drop_seconds := 3.6
@export var result_seconds := 4.0
## While Danny is still putting chips down, the call waits until he has left
## them alone this long - but never more than max_extension past its time.
@export var grace_seconds := 2.5
@export var max_extension := 6.0
## "Last bets" this long before the call.
@export var last_call_seconds := 2.5

## M015: the betting timer's presets - how long the bets stay open (open and
## ball) and how long the number stands, against the times above. The grace
## after Danny's last change and the ball's drop are the same at every pace.
const PACES := {
	"quick": {"name": "Quick", "betting": 0.5, "result": 0.6},
	"normal": {"name": "Normal", "betting": 1.0, "result": 1.0},
	"relaxed": {"name": "Relaxed", "betting": 1.6, "result": 1.375},
}
const PACE_ORDER: Array[String] = ["quick", "normal", "relaxed"]
const DEFAULT_PACE := "normal"


## The pace after `pace` (round the presets).
static func next_pace(pace: String) -> String:
	var i := PACE_ORDER.find(pace)
	return PACE_ORDER[(i + 1) % PACE_ORDER.size()]


static func pace_name(pace: String) -> String:
	return String(PACES.get(pace, PACES[DEFAULT_PACE]).name)


## The table's limits in words (shown on the table).
func limits_text() -> String:
	return "Table limits:  %s to %s on a number  -  %s other inside bets  -  %s outside bets  -  %s a spin" % [
		Rackets.dollars(min_bet), Rackets.dollars(max_straight), Rackets.dollars(max_inside),
		Rackets.dollars(max_outside), Rackets.dollars(max_total)]
