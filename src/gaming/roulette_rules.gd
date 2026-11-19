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
## Seconds the wheel turns before the ball drops into its pocket (presentation).
@export var spin_seconds := 6.5
