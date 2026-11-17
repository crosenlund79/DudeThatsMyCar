class_name Conversations
extends RefCounted
## What the people of the Riverside Ward say, as short pages with numbered
## answers (pure, no scene). Each page is
##   {speaker, text, options: [{id, text}], effects: {}}
## and an empty page ends the conversation. The money side lives in Rackets;
## effects ask the game for anything outside it ({"police": true}: someone
## runs for the copper once you have gone, {"rounds": n}: rounds for the gun).
## `context` describes the moment: {"gun_drawn": bool, "spare": int rounds
## carried, "time": "4:10 AM", "late": bool (time to go home)}.

const NAMES := {"augie": "Augie", "sal": "Sal", "novak": "Mr. Novak", "lindqvist": "Mr. Lindqvist", "eddie": "Eddie",
	"bed": "Home"}

var rackets: Rackets


func _init(p_rackets: Rackets) -> void:
	rackets = p_rackets


func speaker(who: String) -> String:
	return NAMES.get(who, who.capitalize())


## The first page when you walk up to someone and press E.
func open(who: String, context: Dictionary = {}) -> Dictionary:
	return _say(who, "hello", context)


## The page after choosing an answer (an empty page: the talk is over).
func choose(who: String, option: String, context: Dictionary = {}) -> Dictionary:
	if option == "bye":
		return {}
	return _say(who, option, context)


func _say(who: String, step: String, context: Dictionary) -> Dictionary:
	match who:
		"augie":
			return _augie(step, context)
		"sal":
			return _sal(step, context)
		"novak":
			return _novak(step, context)
		"lindqvist":
			return _lindqvist(step, context)
		"eddie":
			return _eddie(step, context)
		"bed":
			return _bed(step, context)
	return {}


func _page(who: String, text: String, options: Array = [], effects: Dictionary = {}) -> Dictionary:
	var opts := options.duplicate()
	if opts.is_empty() or opts.all(func(o: Dictionary) -> bool: return o.id != "bye"):
		opts.append({"id": "bye", "text": "So long." if opts.is_empty() else "Never mind."})
	return {"speaker": speaker(who), "text": text, "options": opts, "effects": effects}


# ------------------------------------------------------------------ Augie, the Copper Owl's bartender

func _augie(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	match step:
		"hello":
			var opts := []
			if r.bottles > 0:
				opts.append({"id": "sell", "text": "I've got %d bottles of rye for you." % r.bottles})
			if not r.has_paid("copper_owl"):
				opts.append({"id": "protection", "text": "Time to pay your insurance, Augie."})
			opts.append({"id": "news", "text": "How's business?"})
			var hello := "Evening. Keep it down, the swells are dancing."
			if r.has_paid("copper_owl"):
				hello = "You again. I paid already, remember?" if r.paid.copper_owl == "leaned" else "Evening. What'll it be?"
			return _page("augie", hello, opts)
		"sell":
			if r.bar_demand() == 0:
				return _page("augie", "Cellar's full tonight, pal. Bring me more tomorrow night.")
			var price := r.bar_price()
			var k := r.sell_bottles()
			var paid_out := Rackets.dollars(k * price)
			if price < r.rules.bar_price:
				return _page("augie", "%d bottles at %s a piece. That's what a shakedown buys you. %s, and not a cent more." % [k, Rackets.dollars(price), paid_out],
					[], {"sold": k})
			return _page("augie", "The real McCoy, straight off the boat? I'll take %d. Here's %s." % [k, paid_out], [], {"sold": k})
		"protection":
			if r.has_paid("copper_owl"):
				return _page("augie", "I paid you already. Come back tomorrow night.")
			return _page("augie", "Insurance? Against what, exactly?", [
				{"id": "ask", "text": "Fires. Broken windows. You know how it is."},
				{"id": "lean", "text": "Don't make me ask twice." if not context.get("gun_drawn", false) else "(Rest the .45 on the bar.)"},
			])
		"ask":
			var got := r.collect("copper_owl", false)
			if got == 0:
				return _page("augie", "I paid you already. Come back tomorrow night.")
			return _page("augie", "%s. The till's thin, the band costs money. Same time tomorrow, I suppose." % Rackets.dollars(got), [], {"paid": got})
		"lean":
			var got2 := r.collect("copper_owl", true)
			if got2 == 0:
				return _page("augie", "I paid you already. Come back tomorrow night.")
			return _page("augie", "All right, all right! %s. And you can forget top dollar for your hooch tonight." % Rackets.dollars(got2),
				[], {"paid": got2})
		"news":
			if r.bar_demand() == 0:
				return _page("augie", "Busy. The cellar's full and so are the tables.")
			return _page("augie", "Could use a few more bottles of rye. Sal down the street keeps a cupboard, if you follow me.")
	return {}


# ------------------------------------------------------------------ Sal, the barber who keeps a cupboard

func _sal(step: String, _context: Dictionary) -> Dictionary:
	var r := rackets
	var price := Rackets.dollars(r.rules.barber_price)
	match step:
		"hello":
			if r.barber_stock() == 0:
				return _page("sal", "Shave and a haircut? Ah, it's you. The cupboard's bare till tomorrow night.")
			var opts := [{"id": "buy2", "text": "Two bottles of the good stuff. (%s each)" % price}]
			if r.barber_stock() > 2:
				opts.append({"id": "buy_all", "text": "Give me all you can spare."})
			return _page("sal", "Shave and a haircut? Ah, it's you. Lower your voice, the walls have ears.", opts)
		"buy2", "buy_all":
			var want := 2 if step == "buy2" else r.rules.carry_limit
			if r.barber_stock() == 0:
				return _page("sal", "The cupboard's bare till tomorrow night.")
			if r.room_to_carry() == 0:
				return _page("sal", "You can't hide another bottle under that coat, friend.")
			if r.money < r.rules.barber_price:
				return _page("sal", "Cash on the barrelhead, friend. %s a bottle." % price)
			var k := r.buy_bottles(want)
			var cost := Rackets.dollars(k * r.rules.barber_price)
			var tail := " That's the last of it tonight." if r.barber_stock() == 0 else ""
			return _page("sal", "%d bottles of Canadian rye, wrapped in yesterday's Tribune. %s.%s" % [k, cost, tail], [], {"bought": k})
	return {}


# ------------------------------------------------------------------ Mr. Novak, the grocer

func _novak(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	match step:
		"hello":
			if r.has_paid("grocery"):
				var again := "You again? I paid! There is nothing left in the till, look for yourself." if r.paid.grocery == "asked" \
					else "Please. I have nothing more. Please go."
				return _page("novak", again, [{"id": "apples", "text": "Just an apple, Mr. Novak."}])
			return _page("novak", "We're closing. Oh. It's you.", [
				{"id": "protection", "text": "It's Friday somewhere, Mr. Novak. Protection."},
				{"id": "apples", "text": "Just an apple."},
			])
		"protection":
			if r.has_paid("grocery"):
				return _page("novak", "I paid already tonight!")
			return _page("novak", "Again? Business is terrible. Nobody has money, the Depression...", [
				{"id": "ask", "text": "Everybody's got troubles. Pay up and you won't have mine."},
				{"id": "lean", "text": "(Sweep a row of tins off the shelf.)" if not context.get("gun_drawn", false) else "(Show him the .45.)"},
			])
		"ask":
			var got := r.collect("grocery", false)
			if got == 0:
				return _page("novak", "I paid already tonight!")
			return _page("novak", "Here. %s. My wife will kill me. Same as always, yes? Same as always." % Rackets.dollars(got), [], {"paid": got})
		"lean":
			var got2 := r.collect("grocery", true)
			if got2 == 0:
				return _page("novak", "I paid already tonight!")
			return _page("novak", "Take it! %s, everything, take it and go!\n(His eyes keep going to the door. He won't keep quiet about this.)" % Rackets.dollars(got2),
				[], {"paid": got2, "police": true})
		"apples":
			return _page("novak", "Take one. Take one and go, please. On the house.")
	return {}


# ------------------------------------------------------------------ Mr. Lindqvist, hardware

func _lindqvist(step: String, _context: Dictionary) -> Dictionary:
	match step:
		"hello":
			return _page("lindqvist", "Lindqvist Hardware. Nails, paint, rope. Something else, maybe?", [
				{"id": "back", "text": "Is Eddie in the back?"},
				{"id": "rope", "text": "Just looking at the rope."},
			])
		"back":
			return _page("lindqvist", "Through the door. Knock first. And I didn't see you.")
		"rope":
			return _page("lindqvist", "Good rope. Holds anything. I don't ask what.")
	return {}


# ------------------------------------------------------------------ Eddie, the back-room dealer

func _eddie(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var spare: int = context.get("spare", 0)
	var price := Rackets.dollars(r.rules.ammo_price)
	match step:
		"hello":
			return _page("eddie", "Well, if it ain't the Copper Owl's errand boy. Pull up a chair. Don't touch the crate.", [
				{"id": "ammo", "text": "A box of .45 rounds. (%s for %d)" % [price, r.rules.ammo_box]},
				{"id": "heavy", "text": "Got anything heavier?"},
			])
		"ammo":
			if spare < 0:
				return _page("eddie", "You're carrying enough lead to sink a rowboat already.")
			if r.money < r.rules.ammo_price:
				return _page("eddie", "Money first, pal. This ain't the Salvation Army.")
			var k := r.buy_ammo(spare)
			if k == 0:
				return _page("eddie", "You're carrying enough lead to sink a rowboat already.")
			return _page("eddie", "%d rounds of .45, still in the paper. %s. Don't say where you got 'em." % [k, price], [], {"rounds": k})
		"heavy":
			return _page("eddie", "A Thompson costs more than you make in a year, kid. Come back when you're somebody.")
	return {}


# ------------------------------------------------------------------ your own bed

func _bed(step: String, context: Dictionary) -> Dictionary:
	match step:
		"hello":
			var line := "The sky's going grey over the El. Time to turn in." if context.get("late", false) \
				else "Only %s. The night's still young out there." % context.get("time", "")
			return _page("bed", line, [
				{"id": "sleep", "text": "Sleep through the day."},
				{"id": "bye", "text": "Not yet."},
			])
		"sleep":
			return _page("bed", "You hang up your hat, pull the blind and sleep like the dead.", [], {"sleep": true})
	return {}
