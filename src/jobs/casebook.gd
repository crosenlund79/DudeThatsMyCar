class_name Casebook
extends RefCounted
## M015: Danny's notebook as case sheets (pure). Every piece of business he
## knows of - Rourke's jobs, his own errands and jobs, a borrowed gun, a car he
## took - is a sheet: the things, persons and places involved, where it
## stands, what he knows, what he doesn't, and the leads he has. Only what he
## has been told or found out: a sheet grows as he learns, an unknown stays an
## unknown until somebody tells him. Settled business stays in the book as a
## closed case (Rourke's jobs, Leon's freight, Lefty's speedster, and the last
## nights' errands from their history), so it can be looked back on.
##
## Each sheet also says where the work points next (`marks`, by stable place
## id - CityLocations - so nothing here is a position): a "sure" mark for what
## he knows he has to do (a quiet badge nearby, an arrow at the edge of the
## view, a ring on the city map), an unsure one for work he could reasonably
## suspect is there (a fainter badge, a dashed ring); hidden work has none.
##
## A sheet: {id, title, who (whose business: "Rourke" or "Your own"), status
## ("open", "lead": suspected, "closed", "lapsed"), standing (one line),
## things, persons, places, known, unknown, leads: [String],
## marks: [{at: place id, inside: place id or "", label, sure}]}.

const OPEN := "open"
const LEAD := "lead"
const CLOSED := "closed"
const LAPSED := "lapsed"

## Where things are (CityLocations ids).
const ROURKE := "riverside/spot/copper_owl/rourke"
const OWL_DOOR := "riverside/door/copper_owl/0"
const HARDWARE_DOOR := "riverside/door/hardware/0"
const LINDQVIST := "riverside/spot/hardware/lindqvist"
const EDDIE := "riverside/spot/hardware/eddie"
const LEFTY := "riverside/place/lefty_post"
const GROCERY_DOOR := "riverside/door/grocery/0"
const NOVAK := "riverside/spot/grocery/novak"
const CAFE_CAR := "halloran/cafe/car"
const CAFE_BENCH := "halloran/cafe/bench"
const DUTCH := "yards/contact/dutch"
const CRATE := "yards/errand/crate"
const FEENEY := "halloran/contact/feeney"
const FILM_CAN := "halloran/errand/film_can"
const DISPATCH_DOOR := "yards/door/dispatch_office/0"
const LEON := "yards/spot/dispatch_office/leon"
const SHED_DOOR := "yards/door/freight_shed/0"
const WALT := "yards/spot/freight_shed/walt"
const UNION_BOARD := "riverside/spot/union_hall/union_board"


## Every sheet, open business first (what he knows he must do, then what he
## suspects), then the closed ones, newest first. `minute`: the night clock.
static func cases(r: Rackets, minute: float) -> Array:
	var all := []
	_rourke_job(r, all)
	_cafe_job(r, all)
	_freight(r, all)
	_crate(r, minute, all)
	_reel(r, minute, all)
	_history(r, all)
	_thompson(r, all)
	_leftys_car(r, all)
	_stall(r, all)  # M015.13
	_sa_man(r, all)
	_bird_card(r, all)
	var order := {OPEN: 0, LEAD: 1, CLOSED: 2, LAPSED: 2}
	var out := []
	for rank in [0, 1, 2]:
		for c in all:
			if int(order[c.status]) == rank:
				out.append(c)
	return out


## The open and suspected sheets' marks, each with its case's title: [{at, inside, label, sure, case}].
static func marks(sheets: Array) -> Array:
	var out := []
	for c in sheets:
		if c.status != OPEN and c.status != LEAD:
			continue
		for m in c.marks:
			var mark: Dictionary = (m as Dictionary).duplicate()
			mark["case"] = c.title
			mark["sure"] = bool(m.sure) and c.status == OPEN
			out.append(mark)
	return out


static func _sheet(id: String, title: String, who: String, status: String, standing: String) -> Dictionary:
	return {"id": id, "title": title, "who": who, "status": status, "standing": standing, "things": [], "persons": [],
		"places": [], "known": [], "unknown": [], "leads": [], "marks": []}


static func _mark(c: Dictionary, at: String, label: String, sure := true, inside := "") -> void:
	(c.marks as Array).append({"at": at, "inside": inside, "label": label, "sure": sure})


# ------------------------------------------------------------------ Rourke: Lindqvist Hardware

static func _rourke_job(r: Rackets, out: Array) -> void:
	var j := r.job
	if j.stage == RourkeJob.Stage.NOT_OFFERED:
		return
	var c := _sheet("rourke_lindqvist", "Collecting at Lindqvist's", "Rourke", OPEN, "")
	c.things.append("Protection money - collected at Lindqvist Hardware without Rourke's say-so")
	c.persons.append("Mr. Rourke - your boss; his corner table at the Copper Owl")
	c.persons.append("Mr. Lindqvist - owns Lindqvist Hardware")
	c.places.append("The Copper Owl, Marlowe Avenue")
	c.places.append("Lindqvist Hardware")
	c.known.append("Somebody's been collecting at Lindqvist Hardware, and it isn't Rourke's people.")
	if j.knows_culprit():
		c.persons.append("Lefty Moran - camel coat, white hat; from the North Side")
		c.places.append("Outside Doyle's Garage, Pruitt Street (Lefty's corner)")
		c.known.append("It's Lefty Moran: eight dollars every Friday for a month, or the windows go.")
		c.known.append("He stands about outside Doyle's Garage on Pruitt Street.")
	if j.learned.has("tip"):
		c.persons.append("Eddie - Lindqvist's back room")
		c.known.append("Eddie says Lefty leads with his right and drops his left shoulder when he does.")
	match j.stage:
		RourkeJob.Stage.OFFERED:
			c.standing = "Rourke has offered you the job. He's waiting on an answer."
			c.unknown.append("Who's doing the collecting.")
			c.leads.append("Tell Rourke yes, or put it off - he won't wait for ever.")
			_mark(c, OWL_DOOR, "Rourke", true, ROURKE)
		RourkeJob.Stage.ACCEPTED, RourkeJob.Stage.RESOLVED:
			c.known.append("You took the job.")
			if j.outcome != "":
				c.standing = "Lefty's settled. Rourke will want to hear how it went."
				c.known.append(_outcome_line(j.outcome))
				if j.recovered > 0:
					c.things.append("%s Lefty handed back" % Rackets.dollars(j.recovered))
				c.leads.append("Tell Rourke at his table in the Copper Owl.")
				_mark(c, OWL_DOOR, "Rourke", true, ROURKE)
			elif not j.knows_culprit():
				c.standing = "Find out who's been collecting at Lindqvist Hardware."
				c.unknown.append("Who's doing the collecting, and where to find him.")
				c.leads.append("Ask Mr. Lindqvist himself - he'll know who comes round on Fridays.")
				_mark(c, HARDWARE_DOOR, "Mr. Lindqvist", true, LINDQVIST)
			else:
				c.standing = "Settle it with Lefty Moran."
				c.unknown.append("Whether Lefty can be talked round, or has to be leaned on.")
				if not j.learned.has("tip"):
					c.unknown.append("How Lefty handles himself in a fight.")
					c.leads.append("Eddie in Lindqvist's back room knows everybody's business.")
				c.leads.append("Talk to him, lean on him, or use your fists. Nobody needs shooting.")
				if not j.lefty_shot:
					_mark(c, LEFTY, "Lefty Moran")
		RourkeJob.Stage.REPORTED:
			if j.outcome == "" and j.told == "handled":
				c.standing = "You told Rourke it was handled. It isn't - Lefty's still collecting."
				c.known.append("Rourke thinks the job's done.")
				c.unknown.append("How long before Rourke hears otherwise.")
				c.leads.append("Make it true: settle it with Lefty before the talk reaches Rourke.")
				_mark(c, LEFTY, "Lefty Moran")
			else:
				c.status = CLOSED
				c.standing = "Done. " + _verdict_line(j.verdict)
				if j.outcome != "":
					c.known.append(_outcome_line(j.outcome))
				c.known.append("You told Rourke: %s." % _told_line(j.told))
		RourkeJob.Stage.DECLINED:
			c.status = CLOSED
			c.standing = "You turned Rourke down. Somebody else got the job."
		RourkeJob.Stage.MOOT:
			c.status = CLOSED
			c.standing = "Lefty Moran's dead. There's nothing left to settle."
	out.append(c)


static func _outcome_line(outcome: String) -> String:
	match outcome:
		"deal":
			return "Lefty listened to reason and handed back what he had."
		"backed_down":
			return "Lefty backed down when you leaned on him."
		"beaten":
			return "You beat Lefty in a fair fight. He's off Lindqvist's back."
		"killed":
			return "Lefty Moran is dead."
	return "It's settled."


static func _told_line(told: String) -> String:
	match told:
		"handled":
			return "it was handled"
		"deal":
			return "you talked Lefty round"
		"backed_down":
			return "Lefty backed down"
		"beaten":
			return "you beat him"
		"killed":
			return "Lefty's dead"
	return "how it went"


static func _verdict_line(verdict: String) -> String:
	match verdict:
		"pleased":
			return "Rourke was pleased."
		"satisfied":
			return "Rourke was satisfied."
		"uneasy":
			return "Rourke was uneasy about how it went."
		"lied_to":
			return "Rourke knows you lied to him."
		"disappointed":
			return "Rourke was disappointed."
	return ""


# ------------------------------------------------------------------ Rourke: Rosie's Café

static func _cafe_job(r: Rackets, out: Array) -> void:
	var j := r.cafe
	if j.stage == CafeJob.Stage.NOT_OFFERED:
		return
	var c := _sheet("rourke_cafe", "Duggan's Packard", "Rourke", OPEN, "")
	c.things.append("Vince Duggan's Packard")
	c.persons.append("Mr. Rourke - wants it dealt with")
	c.persons.append("Vince Duggan - owns the Packard; drinks at Rosie's")
	c.places.append("Rosie's Café, Marlowe Avenue, Halloran Square")
	c.known.append("The Packard stands outside Rosie's Café from ten till two.")
	match j.stage:
		CafeJob.Stage.OFFERED:
			c.standing = "Rourke has another job for you. He's waiting on an answer."
			c.leads.append("Give Rourke your answer at the Copper Owl.")
			_mark(c, OWL_DOOR, "Rourke", true, ROURKE)
		CafeJob.Stage.ACCEPTED:
			c.known.append("You took the job.")
			c.persons.append("Eddie - Lindqvist's back room")
			c.places.append("Lindqvist Hardware (Eddie's back room)")
			if r.parcels > 0:
				c.things.append("Eddie's parcel - in your coat")
				c.standing = "The parcel's in your coat. The Packard's outside Rosie's from ten till two."
				c.leads.append("Under the Packard, then get clear: too close is too close.")
				_mark(c, CAFE_CAR, "Duggan's Packard")
			else:
				c.standing = "You'll want one of Eddie's parcels first."
				c.unknown.append("Where to watch from, once it's done.")
				c.leads.append("Eddie sells a parcel in the back of Lindqvist Hardware.")
				_mark(c, HARDWARE_DOOR, "Eddie", true, EDDIE)
				_mark(c, CAFE_CAR, "Duggan's Packard", false)
		CafeJob.Stage.PLANTED:
			c.things.append("Eddie's parcel - under the Packard")
			c.standing = "The parcel's under the Packard. Get clear and watch."
			c.leads.append("The bench in front of Halloran Drugs has a view of the street.")
			_mark(c, CAFE_BENCH, "A place to watch from")
		CafeJob.Stage.DONE:
			c.standing = "It's done. Rourke will want to hear it from you."
			c.known.append("The Packard went up outside Rosie's.")
			if j.seen:
				c.known.append("A copper saw you by the car. The police know your face now.")
			c.leads.append("Tell Rourke at the Copper Owl.")
			_mark(c, OWL_DOOR, "Rourke", true, ROURKE)
		CafeJob.Stage.REPORTED:
			c.status = CLOSED
			c.standing = "Done, and Rourke paid." if j.paid else "Done."
			c.known.append("The Packard went up outside Rosie's.")
	out.append(c)


# ------------------------------------------------------------------ your own: Leon's freight

static func _freight(r: Rackets, out: Array) -> void:
	var f := r.freight
	if f.stage == FreightJob.Stage.NOT_OFFERED:
		return
	var c := _sheet("freight", "Freight doesn't walk", "Your own", OPEN, f.objective())
	c.things.append("Twelve crates of radio cabinets, under a tarpaulin in the freight shed")
	c.persons.append("Leon Sobczak - North Branch Freight's night dispatcher")
	c.places.append("North Branch Freight - the dispatch office and the freight shed, Riverfront Yards")
	c.known.append("The crates have to go out on the %s truck, or the company puts it on Leon." % FreightJob._clock(f.deadline))
	c.known.append("The shed gang won't load them, and nobody's told the company man why.")
	if f.learned.has("consignee"):
		c.known.append("They're for %s on State Street." % FreightJob.CONSIGNEE)
	if f.learned.has("docked") or f.learned.has("walt_said"):
		c.persons.append("Walt Haney - runs the freight shed")
		c.known.append("The company docked Walt's gang six dollars for a crate dropped last week. Walt's holding the freight till it's put right.")
	else:
		c.unknown.append("Why the shed won't load them.")
		c.leads.append("Walt Haney runs the shed. Dutch at the Night Lunch hears the yards' talk. The union hall keeps a noticeboard.")
	if f.leon_agreed:
		c.known.append("Leon will put the six back out of petty cash.")
	match f.stage:
		FreightJob.Stage.OFFERED:
			c.leads.append("Leon's waiting on an answer in the dispatch office.")
			_mark(c, DISPATCH_DOOR, "Leon Sobczak", true, LEON)
		FreightJob.Stage.ACCEPTED:
			c.known.append("You said you'd see to it.")
			if f.learned.has("docked") or f.learned.has("walt_said"):
				c.leads.append("Square it with Leon, pay the six yourself - or settle it with Walt some other way.")
				_mark(c, SHED_DOOR, "Walt Haney", true, WALT)
				if not f.leon_agreed:
					_mark(c, DISPATCH_DOOR, "Leon Sobczak", false, LEON)
			else:
				_mark(c, SHED_DOOR, "The freight shed", true, WALT)
				_mark(c, DUTCH, "Dutch", false)
				_mark(c, UNION_BOARD, "The union noticeboard", false)
		FreightJob.Stage.SETTLED:
			c.known.append("The freight's loaded.")
			c.leads.append("Leon owes you ten dollars.")
			_mark(c, DISPATCH_DOOR, "Leon Sobczak", true, LEON)
		FreightJob.Stage.PAID:
			c.status = CLOSED
			c.standing = "The freight went out and Leon paid. %s" % _freight_how(f.how)
		FreightJob.Stage.DECLINED:
			c.status = CLOSED
			c.standing = "You told Leon it was his problem."
		FreightJob.Stage.LAPSED:
			c.status = LAPSED
			c.standing = "The truck went without the crates. Leon paid the six out of his own pocket."
	out.append(c)


static func _freight_how(how: String) -> String:
	match how:
		"squared":
			return "Leon put the six back, on your word."
		"paid":
			return "You paid the six yourself."
		"leaned":
			return "You showed Walt your gun."
		"beaten":
			return "You beat Walt in a fight."
	return ""


# ------------------------------------------------------------------ your own: tonight's errands

## Whether Danny has had dealings with `who` (a memory of him, or a job done or dropped).
static func knows(r: Rackets, who: String) -> bool:
	if r.memory.entries.has(who):
		return true
	var what := "crate" if who == "dutch" else "reel"
	for e in r.opportunities.history:
		if e.what == what and e.outcome in ["delivered", "dropped", "returned"]:
			return true
	return false


static func _crate(r: Rackets, minute: float, out: Array) -> void:
	var o := r.opportunities
	var c := _sheet("crate_%d" % o.night, "Dutch's crate", "Your own", OPEN, "")
	c.persons.append("Dutch - the Night Lunch on Foundry Street, Riverfront Yards")
	c.places.append("The Night Lunch, Foundry Street")
	match o.crate:
		"waiting":
			if minute >= Opportunities.CRATE_UNTIL or not knows(r, "dutch"):
				return  # (he only asks a driver he knows; after half past eleven his nephew takes it)
			c.status = LEAD
			c.standing = "Dutch sometimes has a crate that wants carrying."
			c.unknown.append("Whether he has one tonight, and where it goes.")
			c.leads.append("Ask at the Night Lunch before half past eleven.")
			_mark(c, DUTCH, "Dutch", false)
		"taken", "loaded":
			c.things.append("A crate \"off a boxcar\"")
			c.persons.append("Mr. Novak - Novak's Grocery")
			c.places.append("Novak's Grocery, Riverside Ward")
			c.known.append("Novak pays %s on delivery - before two." % Rackets.dollars(Opportunities.CRATE_PAY))
			if o.crate == "taken":
				c.standing = "Load the crate into a car at the Night Lunch."
				c.leads.append("Bring a car up to the counter; the crate goes in the boot.")
				_mark(c, CRATE, "Dutch's crate")
			else:
				c.things.append("A car with the crate in the boot")
				c.standing = "The crate's in the boot. Novak's Grocery, before two."
				_mark(c, GROCERY_DOOR, "Mr. Novak", true, NOVAK)
		_:
			return
	out.append(c)


static func _reel(r: Rackets, minute: float, out: Array) -> void:
	var o := r.opportunities
	var c := _sheet("reel_%d" % o.night, "The Bijou's reel", "Your own", OPEN, "")
	c.persons.append("Mr. Feeney - manages the Bijou, Halloran Square")
	c.places.append("The Bijou, Halloran Square")
	match o.reel:
		"lost":
			if minute >= Opportunities.REEL_SHOW or not knows(r, "feeney"):
				return
			c.status = LEAD
			c.standing = "The film exchange's boy has lost a reel before."
			c.unknown.append("Whether the late show's reel came tonight.")
			c.leads.append("Mr. Feeney will be under the marquee, before eleven.")
			_mark(c, FEENEY, "Mr. Feeney", false)
		"looking", "found":
			c.things.append("A can of film - the late show's reel")
			c.places.append("Behind St. Brendan's")
			c.known.append("The late show's at eleven. Mr. Feeney pays %s if he has the reel by then." % Rackets.dollars(Opportunities.REEL_PAY))
			if o.reel == "looking":
				c.standing = "Find the Bijou's missing reel before eleven."
				c.known.append("The exchange's boy says he set the can down behind St. Brendan's.")
				c.unknown.append("Exactly where behind the church.")
				_mark(c, FILM_CAN, "Behind St. Brendan's")
			else:
				c.standing = "You have the film can. Mr. Feeney, before eleven."
				_mark(c, FEENEY, "Mr. Feeney")
		_:
			return
	out.append(c)


## The last nights' errands Danny had a hand in, closed (newest first).
static func _history(r: Rackets, out: Array) -> void:
	var h: Array = r.opportunities.history
	for i in range(h.size() - 1, -1, -1):
		var e: Dictionary = h[i]
		var c := {}
		match [e.what, e.outcome]:
			["crate", "delivered"]:
				c = _sheet("crate_%d" % int(e.night), "Dutch's crate", "Your own", CLOSED, "Delivered to Novak's. Paid.")
			["crate", "dropped"]:
				c = _sheet("crate_%d" % int(e.night), "Dutch's crate", "Your own", LAPSED, "Never got to Novak's. Dutch's nephew had to fetch it, and Dutch remembers.")
			["reel", "returned"]:
				c = _sheet("reel_%d" % int(e.night), "The Bijou's reel", "Your own", CLOSED, "Back at the Bijou in time for the late show. Paid.")
			["reel", "cancelled"]:
				if not r.opportunities.reel_promised or int(e.night) != r.opportunities.night:
					continue
				c = _sheet("reel_%d" % int(e.night), "The Bijou's reel", "Your own", LAPSED, "The late show was cancelled. You'd said you'd find it.")
			_:
				continue
		c.known.append("Night %d." % int(e.night))
		out.append(c)


# ------------------------------------------------------------------ a borrowed gun, a car taken

static func _thompson(r: Rackets, out: Array) -> void:
	if not r.loan.out and r.loan.lent == 0:
		return
	var c := _sheet("thompson", "Eddie's Thompson", "Your own", OPEN if r.loan.out else CLOSED, "")
	c.things.append("A Thompson submachine gun - Eddie's, on loan")
	c.persons.append("Eddie - Lindqvist's back room")
	c.places.append("Lindqvist Hardware (the back room)")
	if r.loan.out:
		c.standing = "On loan to you. It goes back to Eddie."
		c.known.append("Eddie holds your deposit till it's back; he keeps a dollar for his trouble.")
		if r.loan.overdue(r.night):
			c.known.append("He's been waiting on it %d nights." % (r.night - r.loan.since))
		c.leads.append("Bring it back to the back room of Lindqvist Hardware.")
		_mark(c, HARDWARE_DOOR, "Eddie", r.loan.overdue(r.night), EDDIE)
	else:
		c.standing = "Back with Eddie."
	out.append(c)


static func _leftys_car(r: Rackets, out: Array) -> void:
	var m := r.lefty_car
	if m.knows != "danny":
		return  # (what Lefty knows or doesn't, Danny can't tell until Lefty shows it)
	var c := _sheet("leftys_car", "Lefty's speedster", "Your own", OPEN, "")
	c.things.append("Lefty Moran's speedster")
	c.persons.append("Lefty Moran - his corner outside Doyle's Garage")
	c.places.append("Lefty's kerb, Pruitt Street")
	c.known.append("Lefty %s." % {"saw_taken": "saw you take it", "saw_driving": "saw you driving it",
		"word": "heard it from a copper"}.get(m.how, "knows you took it"))
	if m.returned:
		c.status = CLOSED
		c.standing = "Back at his kerb. Lefty's cooled off."
	else:
		c.standing = "Lefty knows you took his car. He'll go for you on sight."
		c.leads.append("Bring it back to his kerb and he might let it go.")
		_mark(c, LEFTY, "Lefty's kerb", false)
	out.append(c)


# ------------------------------------------------------------------ M015.13: the new quarters' business

const HALL_BOARD := "market/spot/market_hall/hall_board"
const HRABAL := "market/spot/market_hall/hrabal"
const HALL_DOOR := "market/door/market_hall/0"
const CHU := "market/spot/golden_lantern/chu"
const KAZ := "market/spot/golden_lantern/kaz"
const LANTERN_DOOR := "market/door/golden_lantern/0"
const BIRD := "riverside/spot/copper_owl/bird"


static func _stall(r: Rackets, out: Array) -> void:
	var L := r.quarters.leads
	if L.stall == QuarterLeads.Stall.UNKNOWN:
		return
	var c := _sheet("stall", "Stall insurance", "Your own", LEAD, "Somebody is collecting from the market's stallholders.")
	c.places.append("The Canal Market Hall, Canal Market")
	c.things.append("\"Stall insurance\" - fifty cents a stall, Saturdays")
	if L.stall_heard.has("board"):
		c.known.append("The market master's notice: fees at the office only, no other collector. Somebody pencilled TELL THAT TO K.")
	if L.stall_heard.has("hrabal"):
		c.persons.append("Josef Hrabal - the market's night butcher")
		c.known.append("Hrabal says a fellow comes round on Saturdays for stall insurance - \"insurance against him\".")
	if L.stall >= QuarterLeads.Stall.KNOWN:
		c.status = OPEN
		c.persons.append("Kaz Wrobel - the collector")
		c.places.append("The Golden Lantern, Market Street - Kaz eats there from eleven to two")
		c.known.append("Henry Chu says it's Kaz Wrobel, and that he eats at the Lantern after his rounds.")
		c.standing = "Kaz Wrobel collects from the stallholders. What you do about it is up to you."
	else:
		c.unknown.append("Who \"K.\" is, and where to find him.")
		c.leads.append("Henry Chu at the Golden Lantern hears everything said at his tables.")
		_mark(c, LANTERN_DOOR, "The Golden Lantern", false, CHU)
		if not L.stall_heard.has("hrabal"):
			_mark(c, HALL_DOOR, "Josef Hrabal", false, HRABAL)
	if L.stall_heard.has("chu"):
		c.persons.append("Henry Chu - the Golden Lantern")
	match L.stall:
		QuarterLeads.Stall.KNOWN, QuarterLeads.Stall.MET:
			c.leads.append("Have a word with Kaz at the Lantern between eleven and two: lean on him, buy him off, or get in on it.")
			if L.kaz_fights_lost > 0:
				c.known.append("Kaz beat you once. He's bigger than he looks sitting down.")
			_mark(c, LANTERN_DOOR, "Kaz Wrobel", true, KAZ)
		QuarterLeads.Stall.SETTLED:
			match L.stall_how:
				"beaten":
					c.standing = "You beat Kaz Wrobel in the Golden Lantern. He's quit the market."
				"bought":
					c.standing = "You paid Kaz Wrobel five dollars to find another market."
				"cut":
					c.standing = "You're in on Kaz's stall insurance: a dollar a night at the Lantern. Hrabal knows."
			if L.thanks_due() > 0:
				c.status = OPEN
				c.leads.append("Hrabal will want to know the insurance man won't be back.")
				_mark(c, HALL_DOOR, "Josef Hrabal", true, HRABAL)
			elif L.stall_how == "cut":
				c.status = OPEN
				if L.kaz_paid_night != r.night:
					c.leads.append("Tonight's dollar is waiting at the Lantern from eleven.")
					_mark(c, LANTERN_DOOR, "Kaz Wrobel", true, KAZ)
			else:
				c.status = CLOSED
				c.known.append("Hrabal thanked you out of the stallholders' tin.")
	out.append(c)


static func _sa_man(r: Rackets, out: Array) -> void:
	var L := r.quarters.leads
	if L.sa == QuarterLeads.Sa.UNKNOWN:
		return
	var c := _sheet("sa_man", "The State's Attorney's man", "Rourke", OPEN,
		"A man from the State's Attorney's office is staying at the Belvedere, asking after Rourke's people.")
	c.persons.append("A man from the State's Attorney's office")
	c.persons.append("Ellery Pratt - the Belvedere's night manager, who told you for a dollar")
	c.places.append("The Belvedere Hotel, Lincoln Boulevard")
	c.unknown.append("Who sent him, and who he's talked to.")
	match L.sa:
		QuarterLeads.Sa.KNOWN:
			c.leads.append("Rourke would want to know. Or you could keep it to yourself.")
			_mark(c, OWL_DOOR, "Rourke", false, ROURKE)
		QuarterLeads.Sa.TOLD:
			c.status = CLOSED
			c.standing = "You told Rourke. He said the right people would hear about it."
		QuarterLeads.Sa.LAPSED:
			c.status = LAPSED
			c.standing = "The State's Attorney's man checked out of the Belvedere. Rourke never heard it from you."
	out.append(c)


static func _bird_card(r: Rackets, out: Array) -> void:
	var L := r.quarters.leads
	if L.card == QuarterLeads.Card.NONE:
		return
	var c := _sheet("bird_card", "A card for the Bird", "Your own", OPEN,
		"The Paradise's bandleader paid you a dollar to take the Bird his card.")
	c.things.append("The bandleader's card: fifteen a week at the Paradise Ballroom")
	c.persons.append("The Paradise Ballroom's bandleader")
	c.persons.append("The Bird - sings at the Copper Owl; Rourke's")
	c.places.append("The Copper Owl, Marlowe Avenue")
	match L.card:
		QuarterLeads.Card.CARRYING:
			c.known.append("The Bird is Rourke's. Rourke might not like the Paradise asking.")
			c.leads.append("Give her the card - or give it to Rourke instead.")
			_mark(c, OWL_DOOR, "The Bird", true, BIRD)
		QuarterLeads.Card.TO_BIRD:
			c.status = CLOSED
			c.standing = "You gave the Bird the card. She kept it."
		QuarterLeads.Card.TO_ROURKE:
			c.status = CLOSED
			c.standing = "You gave the card to Rourke. He said he'd have a word with the bandleader."
		QuarterLeads.Card.LAPSED:
			c.status = LAPSED
			c.standing = "You never gave anybody the card. The bandleader stopped asking."
	out.append(c)
