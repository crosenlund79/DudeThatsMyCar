class_name Conversations
extends RefCounted
## What the people of the Riverside Ward say, as short pages with numbered
## answers (pure, no scene). Each page is
##   {speaker, text, options: [{id, text}], effects: {}}
## and an empty page ends the conversation. The money side lives in Rackets;
## effects ask the game for anything outside it ({"police": true}: someone
## calls the copper, {"rounds": n}: rounds for the gun).
## `context` describes the moment: {"gun_drawn": bool, "spare": int rounds carried}.

const NAMES := {"augie": "Augie", "sal": "Sal"}

var rackets: Rackets


func _init(p_rackets: Rackets) -> void:
	rackets = p_rackets


func speaker(who: String) -> String:
	return NAMES.get(who, who.capitalize())


## The first page when you walk up to someone and press E.
func open(who: String, context: Dictionary = {}) -> Dictionary:
	match who:
		"augie":
			return _augie("hello", context)
		"sal":
			return _sal("hello", context)
	return {}


## The page after choosing an answer (an empty page: the talk is over).
func choose(who: String, option: String, context: Dictionary = {}) -> Dictionary:
	if option == "bye":
		return {}
	match who:
		"augie":
			return _augie(option, context)
		"sal":
			return _sal(option, context)
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
