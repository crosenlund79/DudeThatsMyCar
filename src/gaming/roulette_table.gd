class_name RouletteTable
extends RefCounted
## M013: the wheel run by the croupier, round after round, whether or not
## Danny plays (pure, no scene). M011's wheel waited for Danny's Space; now
## Leo runs it: "place your bets" while the head turns, the ball sent round
## with the bets still open, "no more bets", the ball dropping, the number,
## the payout, a pause, and the next round.
##
## A round, in seconds from its start (RouletteRules): OPEN (bets open, the
## head pushed, the ball picked out of its pocket) for open_seconds; BALL (the
## ball circling, bets still open) until the call; DROP (the number drawn at
## the call, the ball dropping into its pocket) for drop_seconds; RESULT (the
## number shown, Danny paid - once - when the ball comes to rest) for
## result_seconds; then the next round, or CLOSED for the night.
##
## The call comes ball_seconds after the ball is sent round. If Danny has put
## chips down, moved or taken them back this round, Leo waits until Danny has
## left the layout alone for grace_seconds - but never more than max_extension
## past the usual call (a fixed rule, no endless waiting). The number is drawn
## at the call from a fair draw (every pocket 1 in 37); the wheel on screen
## only shows it (RouletteMotion works the ball's last stretch back from it);
## nothing about the timing, the animation or Danny's bets can change it.
##
## Danny's chips and money are in `danny` (his Roulette: the ledger); the
## game moves the money on this table's events. advance(dt) returns them in
## order: {"event": "open"}, {"event": "ball"}, {"event": "last_call"},
## {"event": "no_more_bets"}, {"event": "rest", "number", "paid", "played"}
## (paid: what Danny's chips returned, to be credited - once; played: whether
## he had chips riding on it still), {"event": "round_over"},
## {"event": "closed"} (the night is over, or the croupier is gone).

enum Phase { OPEN, BALL, DROP, RESULT, CLOSED }

const WORDS := {Phase.OPEN: "open", Phase.BALL: "ball", Phase.DROP: "drop", Phase.RESULT: "result", Phase.CLOSED: "closed"}

var rules: RouletteRules
var danny: Roulette
var motion := RouletteMotion.new()
var rng := RandomNumberGenerator.new()
var phase := Phase.OPEN
## Seconds since this round opened.
var round_time := 0.0
var rounds := 0
## The number drawn this round (-1 before the call).
var number := -1
## When Danny last changed his chips this round (round time; -1: he has not).
var changed_at := -1.0
## The night is over: this round is the last.
var closing := false
## Whether Danny's chips rode on this round's number.
var danny_in := false
var _called_last := false


func _init(p_rules: RouletteRules, p_danny: Roulette = null, p_seed := -1) -> void:
	rules = p_rules if p_rules != null else RouletteRules.new()
	danny = p_danny if p_danny != null else Roulette.new(rules)
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()
	motion.drop_time = rules.drop_seconds
	_open()


func betting_open() -> bool:
	return phase == Phase.OPEN or phase == Phase.BALL


## When the call comes (round time): the usual moment, or later while Danny is
## still busy at the layout - never past the limit.
func close_time() -> float:
	var usual := rules.open_seconds + rules.ball_seconds
	if changed_at < 0.0:
		return usual
	return clampf(changed_at + rules.grace_seconds, usual, usual + rules.max_extension)


## Seconds left to bet (0 once the call has come).
func seconds_to_close() -> float:
	return maxf(0.0, close_time() - round_time) if betting_open() else 0.0


## Danny put down, moved or took back chips just now.
func touch() -> void:
	if betting_open():
		changed_at = round_time


func phase_name() -> String:
	return WORDS[phase]


## Moves the table on by `dt` seconds. Returns the events, in order.
func advance(dt: float) -> Array:
	var out := []
	var left := maxf(dt, 0.0)
	var guard := 0
	while left > 0.0 and guard < 32:
		guard += 1
		var to_next := _next_boundary() - round_time
		if phase == Phase.CLOSED:
			motion.advance(left)
			break
		if to_next > left:
			round_time += left
			motion.advance(left)
			_last_call(out)
			break
		round_time += to_next
		motion.advance(to_next)
		left -= to_next
		_last_call(out)
		_cross(out)
	return out


func _next_boundary() -> float:
	match phase:
		Phase.OPEN:
			return rules.open_seconds
		Phase.BALL:
			return close_time()
		Phase.DROP:
			return close_time() + rules.drop_seconds
		Phase.RESULT:
			return close_time() + rules.drop_seconds + rules.result_seconds
	return INF


func _last_call(out: Array) -> void:
	if phase == Phase.BALL and not _called_last and round_time >= close_time() - rules.last_call_seconds:
		_called_last = true
		out.append({"event": "last_call"})


func _cross(out: Array) -> void:
	match phase:
		Phase.OPEN:
			phase = Phase.BALL
			motion.launch()
			out.append({"event": "ball"})
		Phase.BALL:
			# no more bets: the number is drawn now, once, fairly
			number = rng.randi_range(0, 36)
			danny_in = danny.close_with(number)
			phase = Phase.DROP
			motion.drop(number, rules.drop_seconds)
			out.append({"event": "no_more_bets"})
		Phase.DROP:
			phase = Phase.RESULT
			var paid := 0
			var played := danny.phase == Roulette.Phase.SPINNING  # (not if he walked away and was paid then)
			if played:
				paid = danny.settle()
			elif not danny_in:
				danny.note(number)
			out.append({"event": "rest", "number": number, "paid": paid, "played": played})
		Phase.RESULT:
			danny.new_round()
			out.append({"event": "round_over"})
			if closing:
				phase = Phase.CLOSED
				out.append({"event": "closed"})
			else:
				_open()
				out.append({"event": "open"})


func _open() -> void:
	phase = Phase.OPEN
	round_time = 0.0
	number = -1
	changed_at = -1.0
	danny_in = false
	_called_last = false
	rounds += 1
	motion.kick()
	motion.lift()


## Danny walked away from the layout: Leo no longer waits on him.
func left() -> void:
	changed_at = -1.0


## The croupier is gone (or the room let go of): the table stops. Returns what
## is owed to Danny - chips not yet called come back; a number already drawn
## is settled at once.
func halt() -> int:
	var back := 0
	if phase != Phase.CLOSED:
		back = danny.walk_away()  # a number drawn and not yet paid is settled (and goes on the board)
		if phase == Phase.DROP and not danny_in:
			danny.note(number)
	phase = Phase.CLOSED
	return back


## A new night: Leo uncovers the wheel and opens the first round. Returns
## anything still owed to Danny from the night before (nothing, in play: he
## cannot be at the wheel and in bed).
func begin_night() -> int:
	closing = false
	var back := danny.walk_away()
	_open()
	return back
