class_name RourkeJob
extends RefCounted
## Rourke's first job for Danny (M007), pure and saved: somebody has been
## collecting at Lindqvist Hardware on Rourke's ground without his say-so.
## Rourke offers it at the Copper Owl (accept, put it off, or turn it down);
## Mr. Lindqvist tells Danny who and where (Lefty Moran, outside Doyle's
## Garage); Eddie can tell him how Lefty fights; Danny settles it with Lefty
## by talking, by threatening, with his fists - or with a gun - and reports
## to Rourke, truthfully or not. Rourke judges by what Danny tells him and
## what reaches him as talk (a lie comes out when the talk gets to him).
## Not a mission framework: one job, its record and its rules. Money in cents.

enum Stage { NOT_OFFERED, OFFERED, ACCEPTED, DECLINED, RESOLVED, REPORTED, MOOT }

## What Lefty has taken from Lindqvist, what he has on him to hand back,
## and what Rourke pays for a job done (provisional).
const TAKEN := 3200
const RECOVERABLE := 2000
const REWARD := 1000
const KILLED_REWARD := 500
## Put it off this many times and Rourke gives the job to somebody else.
const MAX_POSTPONES := 3

var stage := Stage.NOT_OFFERED
var offered_night := 0
var postpones := 0
var postponed_night := -1
## What Danny has found out: "culprit" (who and where, from Lindqvist), "tip" (how he fights, from Eddie).
var learned := {}
## Every try at Lefty: {night, how ("talk" | "threat" | "fight" | "gun"), result}.
var attempts: Array = []
## How it was settled: "" | "deal" | "backed_down" | "beaten" | "killed".
var outcome := ""
var resolved_night := 0
## Money Lefty handed over (cents), and where it went: "" (Danny has it), "rourke", "lindqvist".
var recovered := 0
var money_went := ""
## What Danny told Rourke: "" | an outcome | "handled" (a lie: not settled) | and whether he hid the money.
var told := ""
var hid_money := false
## Rourke's view: "" | "pleased" | "satisfied" | "uneasy" | "lied_to" | "disappointed".
var verdict := ""
var success := false
## Lies Rourke may find out: {kind: "unresolved" | "money", night, found: bool}.
var lies: Array = []
## Things that close doors for the night (fights lost, bluffs called) and for good (Lefty shot).
var fight_lost_night := -1
var bluff_called_night := -1
var lefty_shot := false
## A line Rourke has waiting the next time Danny sits down (a lie found out).
var rourke_news := ""


# ------------------------------------------------------------------ the offer

## Whether Rourke has the job on his mind tonight (to offer, or to hear about).
func rourke_has_business(night: int) -> bool:
	match stage:
		Stage.NOT_OFFERED:
			return true
		Stage.OFFERED:
			return postponed_night != night
		Stage.ACCEPTED, Stage.RESOLVED:
			return true
	return rourke_news != ""


func offer(r: Rackets, lefty_dead: bool) -> String:
	if lefty_dead:
		stage = Stage.MOOT
		return "moot"
	if stage == Stage.NOT_OFFERED:
		offered_night = r.night
	stage = Stage.OFFERED
	return "offer"


func accept(r: Rackets) -> String:
	stage = Stage.ACCEPTED
	r.boss.trust = mini(100, r.boss.trust + 2)
	r.memory.remember("rourke", "deal", r.night, "took the Lindqvist job")
	return "accepted"


## Put it off; the third time Rourke gives it to somebody else.
func postpone(r: Rackets) -> String:
	postpones += 1
	postponed_night = r.night
	if postpones >= MAX_POSTPONES:
		stage = Stage.DECLINED
		verdict = "disappointed"
		r.boss.trust = maxi(0, r.boss.trust - 4)
		return "given_away"
	if postpones >= 2:
		r.boss.trust = maxi(0, r.boss.trust - 1)
		return "postponed_again"
	return "postponed"


## Turned down: Rourke is disappointed, not an enemy.
func decline(r: Rackets) -> String:
	stage = Stage.DECLINED
	verdict = "disappointed"
	r.boss.trust = maxi(0, r.boss.trust - 5)
	r.memory.remember("rourke", "dispute", r.night, "turned down the Lindqvist job")
	r.boss.hear("Dimes turned down the Lindqvist job", r.night)
	return "declined"


# ------------------------------------------------------------------ finding out

func learn(fact: String) -> void:
	learned[fact] = true


func knows_culprit() -> bool:
	return learned.has("culprit")


## Danny can have it out with Lefty: the job is his and he knows who it is.
func can_confront() -> bool:
	return stage == Stage.ACCEPTED and knows_culprit() and outcome == ""


# ------------------------------------------------------------------ settling it

## Whether a threat works. `ctx`: gun_drawn, danny_worst (BodyCondition.Level),
## lefty_hurt (he is wounded), night. Points for a drawn gun, for being in one
## piece, for Lefty being hurt and for knowing how he fights; against being
## badly hurt, having lost a fight to him and a bluff he has already called.
func threat_score(ctx: Dictionary) -> int:
	var s := 0
	if ctx.get("gun_drawn", false):
		s += 2
	var worst: int = ctx.get("danny_worst", 0)
	if worst < BodyCondition.Level.WOUNDED:
		s += 1
	elif worst >= BodyCondition.Level.CRITICAL:
		s -= 2
	if ctx.get("lefty_hurt", false):
		s += 2
	if learned.has("tip"):
		s += 1
	if fight_lost_night >= 0:
		s -= 3
	if bluff_called_night >= 0:
		s -= 1
	return s


func threat_works(ctx: Dictionary) -> bool:
	return threat_score(ctx) >= 2


## Lefty will still talk (not after Danny has shot him).
func lefty_talks() -> bool:
	return not lefty_shot


## Lefty will put up his fists (not twice in a night after beating Danny).
func lefty_fights(night: int) -> bool:
	return fight_lost_night != night


func record(how: String, result: String, night: int) -> void:
	attempts.append({"night": night, "how": how, "result": result})


## Settled: how, and what Lefty handed over. The ward hears of it (Lefty
## talks to Eddie, and on it goes); the people involved remember.
func resolve(how: String, r: Rackets) -> void:
	outcome = how
	resolved_night = r.night
	if stage == Stage.ACCEPTED:
		stage = Stage.RESOLVED
	if how in ["backed_down", "beaten"]:
		recovered = RECOVERABLE
		r.money += recovered  # Lefty's money: it comes into the ward from outside
		r.rumours.start("job_paid_back", "lefty", r.night, {"cents": recovered})
	match how:
		"deal":
			r.memory.remember("lefty", "deal", r.night, "a deal over the Swede")
			r.memory.remember("lindqvist", "favour", r.night, "Lefty stopped coming")
			r.rumours.start("job_deal", "lefty", r.night)
		"backed_down":
			r.memory.remember("lefty", "threat", r.night, "made him back down")
			r.memory.remember("lindqvist", "favour", r.night, "Lefty stopped coming")
			r.rumours.start("job_backed_down", "lefty", r.night)
		"beaten":
			r.memory.remember("lefty", "threat", r.night, "beat him with his fists")
			r.memory.remember("lindqvist", "favour", r.night, "Lefty stopped coming")
			r.rumours.start("job_beaten", "lefty", r.night)
		"killed":
			r.memory.remember("lindqvist", "heard_threat", r.night, "Lefty's in the Morgue")
			r.boss.hear("Lefty Moran turned up dead on Pruitt Street", r.night)
			r.rumours.start("job_killed", "lindqvist", r.night)


## Danny lost a fistfight to Lefty: he is hurt, Lefty gloats, the job stays open.
func lost_fight(r: Rackets) -> void:
	fight_lost_night = r.night
	record("fight", "lost", r.night)
	r.rumours.start("job_lost", "lefty", r.night)


## Lefty shot by Danny (the M006 rules apply to the shooting itself).
func shot_lefty(r: Rackets, dead: bool) -> void:
	lefty_shot = true
	record("gun", "killed" if dead else "wounded", r.night)
	if dead and outcome == "":
		if stage in [Stage.ACCEPTED]:
			resolve("killed", r)
		else:
			r.boss.hear("Lefty Moran turned up dead on Pruitt Street", r.night)


## Danny gives Lindqvist back what Lefty handed over.
func return_money(r: Rackets) -> int:
	if recovered <= 0 or money_went != "":
		return 0
	var cents := mini(recovered, r.money)
	r.money -= cents
	money_went = "lindqvist"
	r.memory.remember("lindqvist", "favour", r.night, "brought back his money")
	r.rumours.start("job_returned", "lindqvist", r.night)
	return cents


# ------------------------------------------------------------------ reporting

## What Danny can tell Rourke now: ids for the conversation.
func report_options() -> Array:
	if outcome == "":
		return ["job_working", "job_handled"]
	var opts := []
	if recovered > 0 and money_went == "":
		opts.append("job_truth_hand")
		opts.append("job_truth_keep")
	else:
		opts.append("job_truth")
	return opts


## Danny tells Rourke. `claim`: "job_working", "job_handled" (a lie), "job_truth",
## "job_truth_hand" (and hands over the money), "job_truth_keep" (hides it).
## Returns {lines: [line ids], reward (cents paid to Danny)}.
func report(claim: String, r: Rackets) -> Dictionary:
	var b := r.boss
	var lines: Array = []
	var reward := 0
	match claim:
		"job_working":
			lines.append("report_working")
			if r.night - offered_night >= 2:
				b.trust = maxi(0, b.trust - 1)
			return {"lines": lines, "reward": 0}
		"job_handled":
			told = "handled"
			stage = Stage.REPORTED
			lies.append({"kind": "unresolved", "night": r.night, "found": false})
			verdict = "pleased"
			success = true  # as far as Rourke knows
			reward = _pay(r, REWARD)
			lines.append("report_handled")
			return {"lines": lines, "reward": reward}
	told = outcome
	stage = Stage.REPORTED
	lines.append("report_" + outcome)
	match outcome:
		"deal":
			b.trust = mini(100, b.trust + 3)
			verdict = "satisfied"
		"backed_down", "beaten":
			b.trust = mini(100, b.trust + 6)
			verdict = "pleased"
		"killed":
			b.patience = maxi(0, b.patience - 1)
			verdict = "uneasy"
	if claim == "job_truth_hand" and recovered > 0 and money_went == "":
		var cents := mini(recovered, r.money)
		r.money -= cents
		b.purse += cents
		money_went = "rourke"
		b.trust = mini(100, b.trust + 2)
		lines.append("report_handed")
	elif claim == "job_truth_keep":
		hid_money = true
		lies.append({"kind": "money", "night": r.night, "found": false})
	elif money_went == "lindqvist":
		lines.append("report_returned")
	success = true
	r.memory.remember("rourke", "deal", r.night, "the Lindqvist job: " + outcome)
	reward = _pay(r, KILLED_REWARD if outcome == "killed" else REWARD)
	if reward > 0:
		lines.append("report_reward")
	return {"lines": lines, "reward": reward}


## Rourke pays out of what Danny has handed him (nothing from thin air).
func _pay(r: Rackets, cents: int) -> int:
	var paid := mini(cents, r.boss.purse)
	r.boss.purse -= paid
	r.money += paid
	return paid


# ------------------------------------------------------------------ what Rourke finds out

## A piece of talk reaches Rourke. Returns the line he will have for Danny ("" for none).
func rourke_hears(kind: String, r: Rackets) -> String:
	match kind:
		"job_still":
			for lie in lies:
				if lie.kind == "unresolved" and not lie.found:
					lie.found = true
					_caught(r, REWARD)
					verdict = "lied_to"
					success = false
					stage = Stage.ACCEPTED  # he still wants it done
					told = ""
					rourke_news = "found_unresolved"
					return rourke_news
		"job_paid_back":
			for lie in lies:
				if lie.kind == "money" and not lie.found:
					lie.found = true
					_caught(r, recovered)
					verdict = "lied_to"
					rourke_news = "found_money"
					return rourke_news
		"job_deal", "job_backed_down", "job_beaten":
			r.boss.hear("Dimes settled the Lindqvist business", r.night)
		"job_lost":
			r.boss.hear("Lefty Moran gave Dimes a beating", r.night)
	return ""


func _caught(r: Rackets, owed: int) -> void:
	var b := r.boss
	b.trust = maxi(0, b.trust - 15)
	b.patience = maxi(0, b.patience - 1)
	b.arrears += owed
	b.caught += 1
	r.memory.remember("rourke", "lie", r.night, "the Lindqvist job")
	b.hear("Dimes lied about the Lindqvist job", r.night)
	b._pressure()


## The night is over: if Danny told Rourke it was handled and it is not,
## the Swede is paying Lefty again and says so.
func end_night(r: Rackets) -> void:
	if outcome == "" and told == "handled":
		for lie in lies:
			if lie.kind == "unresolved" and not lie.found and not lie.get("talked", false):
				lie["talked"] = true
				r.rumours.start("job_still", "lindqvist", r.night)


## The line Rourke opens with when he has news for Danny (once).
func take_rourke_news() -> String:
	var n := rourke_news
	rourke_news = ""
	return n


# ------------------------------------------------------------------ the map and the record

## What to do next, in a few words (for the ward map), and where: a place id
## ("copper_owl", "hardware", "lefty") or "".
func objective() -> Dictionary:
	match stage:
		Stage.OFFERED:
			return {"text": "Rourke has work for you (the Copper Owl).", "where": "copper_owl"}
		Stage.ACCEPTED:
			if outcome != "":
				return {"text": "Tell Rourke how it went (the Copper Owl).", "where": "copper_owl"}
			if not knows_culprit():
				return {"text": "Ask Mr. Lindqvist who's been squeezing him (Lindqvist Hardware).", "where": "hardware"}
			return {"text": "Settle it with Lefty Moran (outside Doyle's Garage).", "where": "lefty"}
		Stage.RESOLVED:
			return {"text": "Tell Rourke how it went (the Copper Owl).", "where": "copper_owl"}
		Stage.REPORTED:
			return {"text": "Rourke's job: done (%s)." % _verdict_words(), "where": ""}
		Stage.DECLINED:
			return {"text": "You turned down Rourke's job.", "where": ""}
	return {}


func _verdict_words() -> String:
	match verdict:
		"pleased":
			return "Rourke is pleased"
		"satisfied":
			return "Rourke is satisfied"
		"uneasy":
			return "Rourke is uneasy about it"
		"lied_to":
			return "Rourke knows you lied"
	return "settled"


func to_dict() -> Dictionary:
	return {"stage": stage, "offered_night": offered_night, "postpones": postpones, "postponed_night": postponed_night,
		"learned": learned.keys(), "attempts": attempts.duplicate(true), "outcome": outcome, "resolved_night": resolved_night,
		"recovered": recovered, "money_went": money_went, "told": told, "hid_money": hid_money, "verdict": verdict,
		"success": success, "lies": lies.duplicate(true), "fight_lost_night": fight_lost_night,
		"bluff_called_night": bluff_called_night, "lefty_shot": lefty_shot, "rourke_news": rourke_news}


func from_dict(d: Dictionary) -> void:
	stage = clampi(int(d.get("stage", Stage.NOT_OFFERED)), 0, Stage.MOOT)
	offered_night = int(d.get("offered_night", 0))
	postpones = int(d.get("postpones", 0))
	postponed_night = int(d.get("postponed_night", -1))
	learned = {}
	for f in d.get("learned", []):
		learned[String(f)] = true
	attempts = []
	for a in d.get("attempts", []):
		attempts.append({"night": int(a.night), "how": String(a.how), "result": String(a.result)})
	outcome = String(d.get("outcome", ""))
	resolved_night = int(d.get("resolved_night", 0))
	recovered = int(d.get("recovered", 0))
	money_went = String(d.get("money_went", ""))
	told = String(d.get("told", ""))
	hid_money = bool(d.get("hid_money", false))
	verdict = String(d.get("verdict", ""))
	success = bool(d.get("success", false))
	lies = []
	for l in d.get("lies", []):
		lies.append({"kind": String(l.kind), "night": int(l.night), "found": bool(l.found), "talked": bool(l.get("talked", false))})
	fight_lost_night = int(d.get("fight_lost_night", -1))
	bluff_called_night = int(d.get("bluff_called_night", -1))
	lefty_shot = bool(d.get("lefty_shot", false))
	rourke_news = String(d.get("rourke_news", ""))
