class_name Boss
extends RefCounted
## Rourke, who runs the protection in the Riverside Ward (pure, no scene).
## The protection Danny collects is Rourke's money; Danny keeps a commission
## for his trouble, and his rye trade is his own. Rourke only knows what he
## has seen from his corner table at the Copper Owl, what he has been told
## and what has been said about town (`believe`, `heard`): never what Danny
## actually took off anybody. From that, from what Danny brought him lately
## and from what is still owed, he works out what he expects each night. Pay
## him, explain, keep some back, ask for time, cover a gap, sweeten it: his
## trust and patience follow, and running out of patience costs Danny his
## commission and then his rye trade at the club until they are square.

## How much he trusts Danny (0..100) and how many short nights he will sit through.
var trust := 60
var patience := 3
const PATIENCE := 3
## What he believes Danny still owes him from earlier nights (cents).
var arrears := 0
## What he expects tonight (worked out at the start of the night).
var expected := 0
## His share of the protection he hands back as Danny's end (percent).
var commission := 20
const COMMISSION := 20
## Out of patience: no more of Danny's rye through his club till they are square,
## and how many nights it has lasted (his collectors come after the first).
var ban := false
var ban_nights := 0
## What he believes about each business he collects from:
## id -> "good" | "short" | "broke", and when he learnt it (night).
var belief := {}
var belief_night := {}
## Things he has heard (for his lines), newest last: {night, text}.
var heard: Array = []
## What he has learnt businesses paid Danny ({night, seq, id, cents}; seq
## orders the collections), and the nights Danny told him business was bad
## ({night, seq, handed, judged}). When he learns that more was paid before
## such a claim than Danny handed over, it was a lie - and he finds out
## whenever the news reaches him, even nights later.
var paid_log: Array = []
var claims: Array = []
## What he holds of Danny's hand-overs, all nights (cents; the money leaves the ward).
var purse := 0
## Tonight: whether Danny has settled up, and what he handed over.
var settled := false
var handed := 0
## The last few nights' hand-overs (newest last), and Danny's rye sales he has
## seen go through his club tonight (cents) - he wants his end of those.
var recent: Array = []
var seen_rye := 0
## Whether he has noticed Danny's rye trade at all.
var knows_rye := false
## How many times he caught Danny short-changing him.
var caught := 0


## What he believes a business can pay tonight.
func believed_due(b: Business) -> int:
	match belief.get(b.id, "good"):
		"broke":
			return 0
		"short":
			return b.protection / 2
	return b.protection


## Works out tonight's expectation: what his businesses can pay as far as he
## knows, at least most of what Danny brought lately, what is owed, and his
## end of any rye trade he has seen. A man he trusts less gets less slack.
func expect(town: Neighbourhood) -> int:
	var due := 0
	for b in town.businesses.values():
		if (b as Business).protection > 0:
			due += believed_due(b)
	if not recent.is_empty():
		var avg := 0
		for r in recent:
			avg += int(r)
		avg /= recent.size()
		due = maxi(due, avg * 9 / 10)
	if trust < 40:
		due += due / 10
	expected = due + arrears
	return expected


## His own eyes: from his table he sees how the club is doing.
func observe_club(club: Business, night: int) -> void:
	var state := "good"
	if club.cash < club.protection:
		state = "broke"
	elif club.is_short():
		state = "short"
	learn(club.id, state, night)


func learn(business: String, state: String, night: int) -> void:
	belief[business] = state
	belief_night[business] = night


func hear(text: String, night: int) -> void:
	heard.append({"night": night, "text": text})
	if heard.size() > 8:
		heard.pop_front()


## He watches Danny sell rye to Augie in his club and wants his end of it.
func see_rye_sale(cents: int) -> void:
	knows_rye = true
	seen_rye += cents


## His end of the rye he has seen tonight (a tenth).
func rye_end() -> int:
	return seen_rye / 10


## Danny hands over `cents` tonight, of which `protection_part` is
## protection money (his commission is on that). `claim`: "" or
## "bad_business" when he says the night was thin. Rourke weighs it against
## what he knows - never against what Danny really took. Returns
## {accepted, owed (still owed after this), cut (Danny's end), caught}.
func settle(cents: int, protection_part: int, claim: String, town: Neighbourhood, night: int, seq: int) -> Dictionary:
	settled = true
	handed = cents
	recent.append(cents)
	if recent.size() > 3:
		recent.pop_front()
	var want := expected + rye_end()
	var short := maxi(0, want - cents)
	var out := {"accepted": short == 0, "owed": 0, "cut": 0, "caught": false}
	if short == 0:
		arrears = 0
		patience = PATIENCE
		ban = false
		ban_nights = 0
		trust = mini(100, trust + (5 if cents > want else 3))
		if trust >= 50:
			commission = COMMISSION
	elif claim == "bad_business":
		# does what he knows back Danny up?
		var backed := false
		for b in town.businesses.values():
			var bb := b as Business
			if bb.protection > 0 and belief.get(bb.id, "good") != "good":
				backed = true
		var claim_entry := {"night": night, "seq": seq, "handed": cents, "judged": false}
		claims.append(claim_entry)
		var lie := _judge(claim_entry)
		if lie > 0:
			# he already knows they paid more than that tonight
			out.caught = true
			arrears = short
		elif backed or trust >= 60:
			out.accepted = true
			arrears = 0
			trust = maxi(0, trust - (0 if backed else 2))
		else:
			trust = maxi(0, trust - 5)
			patience = maxi(0, patience - 1)
			arrears = short
	else:
		trust = maxi(0, trust - 6)
		patience = maxi(0, patience - 1)
		arrears = short
	out.owed = arrears
	_pressure()
	out.cut = protection_part * commission / 100 if cents >= protection_part else cents * commission / 100
	return out


## He learns that `business` paid Danny `cents` on night `paid_night`, as
## collection number `seq` (Augie tells him at once; the rest reaches him as
## talk). Returns the cents he now knows Danny kept from him by claiming the
## night was bad (0 when the books agree).
func learn_paid(business: String, cents: int, paid_night: int, seq: int) -> int:
	for p in paid_log:
		if int(p.seq) == seq:
			return 0  # old news
	paid_log.append({"night": paid_night, "seq": seq, "id": business, "cents": cents})
	var missing := 0
	for c in claims:
		missing += _judge(c)
	if missing > 0:
		arrears += missing
		_pressure()
	return missing


## Checks a "business was bad" claim against what he knows was paid before
## it that night: the difference is a lie (once).
func _judge(claim: Dictionary) -> int:
	if claim.judged:
		return 0
	var known := 0
	for p in paid_log:
		if int(p.night) == int(claim.night) and int(p.seq) < int(claim.seq):
			known += int(p.cents)
	var lie := known - int(claim.handed)
	if lie <= 0:
		return 0
	claim.judged = true
	caught += 1
	trust = maxi(0, trust - 20)
	patience = maxi(0, patience - 1)
	hear("caught short-changing him by %s" % Rackets.dollars(lie), int(claim.night))
	return lie


## The night is over. If Danny never came, what was expected is owed.
func end_night(town: Neighbourhood, night: int) -> void:
	if not settled:
		arrears = expected + rye_end()
		trust = maxi(0, trust - 8)
		patience = maxi(0, patience - 1)
		_pressure()
	settled = false
	handed = 0
	seen_rye = 0
	observe_club(town.club(), night)
	# old news fades: after two nights he assumes things are back to normal
	for id in belief_night.keys():
		if night - int(belief_night[id]) > 2:
			belief.erase(id)
			belief_night.erase(id)
	heard = heard.filter(func(h: Dictionary) -> bool: return night - int(h.night) <= 2)
	paid_log = paid_log.filter(func(p: Dictionary) -> bool: return night - int(p.night) <= 6)
	claims = claims.filter(func(c: Dictionary) -> bool: return night - int(c.night) <= 6)
	expect(town)


## Patience running out: a warning, then a smaller end, then no rye through his club.
func _pressure() -> void:
	if patience <= 1:
		commission = COMMISSION / 2
	if patience <= 0:
		ban = true


## How he feels about Danny, for his lines: "warm", "cool", "cold", "angry".
func mood() -> String:
	if ban or patience <= 0:
		return "angry"
	if patience < PATIENCE or trust < 40:
		return "cold"
	if trust >= 75:
		return "warm"
	return "cool"


func to_dict() -> Dictionary:
	return {"trust": trust, "patience": patience, "arrears": arrears, "expected": expected, "commission": commission,
		"ban": ban, "ban_nights": ban_nights, "belief": belief.duplicate(), "belief_night": belief_night.duplicate(), "heard": heard.duplicate(true),
		"settled": settled, "handed": handed, "recent": recent.duplicate(), "seen_rye": seen_rye, "knows_rye": knows_rye,
		"caught": caught, "paid_log": paid_log.duplicate(true), "claims": claims.duplicate(true), "purse": purse}


func from_dict(d: Dictionary) -> void:
	trust = int(d.get("trust", trust))
	patience = int(d.get("patience", patience))
	arrears = int(d.get("arrears", 0))
	expected = int(d.get("expected", 0))
	commission = int(d.get("commission", COMMISSION))
	ban = bool(d.get("ban", false))
	ban_nights = int(d.get("ban_nights", 0))
	belief = (d.get("belief", {}) as Dictionary).duplicate()
	belief_night = {}
	for k in (d.get("belief_night", {}) as Dictionary):
		belief_night[k] = int(d.belief_night[k])
	heard = []
	for h in d.get("heard", []):
		heard.append({"night": int(h.night), "text": String(h.text)})
	settled = bool(d.get("settled", false))
	handed = int(d.get("handed", 0))
	recent = []
	for r in d.get("recent", []):
		recent.append(int(r))
	seen_rye = int(d.get("seen_rye", 0))
	knows_rye = bool(d.get("knows_rye", false))
	caught = int(d.get("caught", 0))
	purse = int(d.get("purse", 0))
	paid_log = []
	for p in d.get("paid_log", []):
		paid_log.append({"night": int(p.night), "seq": int(p.seq), "id": String(p.id), "cents": int(p.cents)})
	claims = []
	for c in d.get("claims", []):
		claims.append({"night": int(c.night), "seq": int(c.seq), "handed": int(c.handed), "judged": bool(c.judged)})
