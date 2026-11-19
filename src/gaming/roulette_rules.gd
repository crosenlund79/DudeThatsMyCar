class_name RouletteRules
extends Resource
## The gaming room's wheel table (default_roulette.tres): the chips the
## croupier sells and the table's limits, in cents. PROVISIONAL, to be tuned
## by playing; small, like the card game's stakes.

## The chip denominations, smallest first.
@export var chips: Array[int] = [5, 10, 25, 100]
## Each bet must be at least this much when the wheel is spun.
@export var min_bet := 5
## The most on one bet: a single number, any other inside bet, an outside bet.
@export var max_straight := 50
@export var max_inside := 100
@export var max_outside := 500
## The most on the whole layout in one spin.
@export var max_total := 1000
## M013: Leo's rounds (seconds): bets open while the head turns, then with the
## ball going round; the call ("no more bets") comes ball_seconds after it is
## sent; the ball drops for drop_seconds; the number stands for result_seconds.
@export var open_seconds := 9.0
@export var ball_seconds := 7.0
@export var drop_seconds := 3.6
@export var result_seconds := 5.5
## While Danny is still putting chips down, the call waits until he has left
## them alone this long - but never more than max_extension past its time.
@export var grace_seconds := 2.5
@export var max_extension := 6.0
## "Last bets" this long before the call.
@export var last_call_seconds := 2.5
