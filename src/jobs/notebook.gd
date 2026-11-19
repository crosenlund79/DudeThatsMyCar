class_name Notebook
extends RefCounted
## M012: what is on Danny's plate tonight, for the Notebook page of the game
## menu (pure): one short entry per piece of business under way - Rourke's
## jobs, the yards' and the square's errands, Eddie's Thompson - in Danny's
## own terms, only what he has been told or found out. Nothing he does not
## know, no arrows, no markers: a page in a notebook.

## The entries: [{title, lines: [String]}] (empty: nothing under way).
## `night_minute`: the clock's minute (some errands have their hour).
static func entries(r: Rackets, night_minute: float) -> Array:
	var out := []
	_rourke_job(r, out)
	_cafe_job(r, out)
	_crate(r, night_minute, out)
	_reel(r, night_minute, out)
	_thompson(r, out)
	return out


static func _add(out: Array, title: String, line: String) -> void:
	out.append({"title": title, "lines": [line]})


static func _rourke_job(r: Rackets, out: Array) -> void:
	var j := r.job
	match j.stage:
		RourkeJob.Stage.OFFERED:
			_add(out, "Rourke - Lindqvist Hardware", "Somebody's been collecting at Lindqvist Hardware without Rourke's say-so. "
				+ "He wants an answer: take it, or put it off.")
		RourkeJob.Stage.ACCEPTED:
			if j.knows_culprit():
				_add(out, "Rourke - Lindqvist Hardware", "Lefty Moran's the one collecting at Lindqvist's. Settle it with him - "
					+ "talk, lean on him, or your fists - then tell Rourke.")
			else:
				_add(out, "Rourke - Lindqvist Hardware", "Find out who's been collecting at Lindqvist Hardware. Start with "
					+ "Mr. Lindqvist himself.")
		RourkeJob.Stage.RESOLVED:
			_add(out, "Rourke - Lindqvist Hardware", "Lefty's settled. Rourke's waiting at his table in the Copper Owl to hear "
				+ "how it went.")


static func _cafe_job(r: Rackets, out: Array) -> void:
	match r.cafe.stage:
		CafeJob.Stage.OFFERED:
			_add(out, "Rourke - Rosie's Café", "Rourke wants Vince Duggan's Packard dealt with, outside Rosie's Café. Your "
				+ "answer's still his to hear.")
		CafeJob.Stage.ACCEPTED:
			var line := "Duggan's Packard stands outside Rosie's Café, Marlowe Avenue, Halloran Square, from ten till two."
			line += " Eddie's parcel is in your coat." if r.parcels > 0 else " You'll want one of Eddie's parcels first."
			_add(out, "Rourke - Rosie's Café", line)
		CafeJob.Stage.PLANTED:
			_add(out, "Rourke - Rosie's Café", "The parcel's under the Packard. Get clear - somewhere you can watch from.")
		CafeJob.Stage.DONE:
			_add(out, "Rourke - Rosie's Café", "It's done. Rourke will want to hear it from you.")


static func _crate(r: Rackets, minute: float, out: Array) -> void:
	match r.opportunities.crate:
		"waiting":
			if minute < Opportunities.CRATE_UNTIL:
				_add(out, "Dutch's crate", "Dutch at the Night Lunch on Foundry Street has a crate that wants carrying, if "
					+ "you want the work.")
		"taken":
			_add(out, "Dutch's crate", "Load Dutch's crate into a car at the Night Lunch and run it to Novak's Grocery "
				+ "before two.")
		"loaded":
			_add(out, "Dutch's crate", "The crate's in the boot. Novak's Grocery, before two.")


static func _reel(r: Rackets, minute: float, out: Array) -> void:
	match r.opportunities.reel:
		"lost":
			if minute < Opportunities.REEL_SHOW:
				_add(out, "The Bijou's reel", "Mr. Feeney at the Bijou is missing a reel for the late show.")
		"looking":
			_add(out, "The Bijou's reel", "Find the Bijou's missing reel before the eleven o'clock show.")
		"found":
			_add(out, "The Bijou's reel", "You have the film can. Mr. Feeney at the Bijou, before eleven.")


static func _thompson(r: Rackets, out: Array) -> void:
	if not r.loan.out:
		return
	var line := "Eddie's Thompson is on loan to you. It goes back to him, in the back of Lindqvist Hardware."
	if r.loan.overdue(r.night):
		line += " He's been waiting on it."
	_add(out, "Eddie's Thompson", line)
