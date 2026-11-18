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
	"rourke": "Rourke", "bed": "Home"}

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
		"rourke":
			return _rourke(step, context)
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
	var c := r.club()
	match step:
		"hello":
			var opts := []
			if r.bottles > 0:
				opts.append({"id": "sell", "text": "I've got %d bottles of rye for you." % r.bottles})
			if not r.has_paid("copper_owl"):
				opts.append({"id": "protection", "text": "Time to pay your insurance, Augie."})
			opts.append({"id": "news", "text": "How's business?"})
			var hello := "Evening. Keep it down, the swells are dancing."
			if r.memory.recent("augie", "threat", r.night, 3) > 0 and not r.has_paid("copper_owl"):
				hello = "Dimes. Last time you leaned on me in my own club. I ain't forgot."
			if r.boss.ban:
				hello = "Rourke's orders, Dimes: not one more bottle from you till you're square with him."
			if c.is_short():
				hello = "Thank God. The cellar's near dry and the swells are thirsty."
			if r.has_paid("copper_owl"):
				hello = "You again. I paid already, remember?" if r.paid.copper_owl == "leaned" else "Evening. What'll it be?"
			return _page("augie", hello, opts)
		"sell":
			if r.bar_demand() == 0:
				if c.stock >= c.capacity:
					return _page("augie", "Cellar's full tonight, pal. Bring me more tomorrow night.")
				return _page("augie", "I'd take it, but the till's empty. Come back when I've sold a few.")
			var price := r.bar_price()
			var k := r.sell_bottles()
			var paid_out := Rackets.dollars(k * price)
			if r.paid.get("copper_owl", "") == "leaned":
				return _page("augie", "%d bottles at %s a piece. That's what a shakedown buys you. %s, and not a cent more." % [k, Rackets.dollars(price), paid_out],
					[], {"sold": k})
			if price > r.rules.bar_price:
				return _page("augie", "You're a lifesaver. %d bottles, and I'll pay over the odds: %s." % [k, paid_out], [], {"sold": k})
			return _page("augie", "The real McCoy, straight off the boat? I'll take %d. Here's %s." % [k, paid_out], [], {"sold": k})
		"protection":
			if r.has_paid("copper_owl"):
				return _page("augie", "I paid you already. Come back tomorrow night.")
			return _page("augie", "Insurance? Against what, exactly?", [
				{"id": "ask", "text": "Fires. Broken windows. You know how it is."},
				{"id": "lean", "text": "Don't make me ask twice." if not context.get("gun_drawn", false) else "(Rest the .45 on the bar.)"},
			])
		"ask", "lean":
			if r.has_paid("copper_owl"):
				return _page("augie", "I paid you already. Come back tomorrow night.")
			var leaned := step == "lean"
			var got := r.collect("copper_owl", leaned)
			if got == 0:
				return _page("augie", "With what? Look at the till. Not a dime till the cellar's full again.", [], {"paid": 0})
			if leaned:
				return _page("augie", "All right, all right! %s. And you can forget top dollar for your hooch tonight." % Rackets.dollars(got),
					[], {"paid": got})
			if got < c.protection:
				return _page("augie", "%s. That's all there is; a dry bar don't make money." % Rackets.dollars(got), [], {"paid": got})
			return _page("augie", "%s. The till's thin, the band costs money. Same time tomorrow, I suppose." % Rackets.dollars(got), [], {"paid": got})
		"news":
			var talk := _talk_line(r.gossip("augie"))
			if talk != "":
				return _page("augie", talk)
			if c.stock >= c.capacity - 2:
				return _page("augie", "Busy. The cellar's full and so are the tables.")
			if c.is_short():
				return _page("augie", "Rotten. No rye, no swells. My man got pinched; Sal down the street keeps a cupboard, if you follow me.")
			if c.trend() < 0:
				return _page("augie", "Thin. The band costs more than the bar brings in some nights.")
			return _page("augie", "Could use a few more bottles of rye. Sal down the street keeps a cupboard, if you follow me.")
	return {}


# ------------------------------------------------------------------ Sal, the barber who keeps a cupboard

func _sal(step: String, _context: Dictionary) -> Dictionary:
	var r := rackets
	var price := Rackets.dollars(r.barber_price())
	match step:
		"hello":
			if r.barber_stock() == 0:
				return _page("sal", "Shave and a haircut? Ah, it's you. The cupboard's bare till my man comes from Cicero.")
			var opts := [{"id": "buy2", "text": "Two bottles of the good stuff. (%s each)" % price}]
			if r.barber_stock() > 2:
				opts.append({"id": "buy_all", "text": "Give me all you can spare."})
			var hello := "Shave and a haircut? Ah, it's you. Lower your voice, the walls have ears."
			opts.append({"id": "news", "text": "Heard anything, Sal?"})
			if r.is_regular():
				hello = "My best customer! For a regular, a dime off the bottle."
			elif r.barber_price() > r.rules.barber_price:
				hello = "Ah, it's you. Only a couple left, so it's %s a bottle tonight." % price
			elif r.barber_price() < r.rules.barber_price:
				hello = "Ah, it's you. The cupboard's full to bursting; %s a bottle, as a friend." % price
			return _page("sal", hello, opts)
		"buy2", "buy_all":
			var want := 2 if step == "buy2" else r.rules.carry_limit
			if r.barber_stock() == 0:
				return _page("sal", "The cupboard's bare till tomorrow night.")
			if r.room_to_carry() == 0:
				return _page("sal", "You can't hide another bottle under that coat, friend.")
			if r.money < r.barber_price():
				return _page("sal", "Cash on the barrelhead, friend. %s a bottle." % price)
			var each := r.barber_price()
			var k := r.buy_bottles(want)
			var cost := Rackets.dollars(k * each)
			var tail := " That's the last of it tonight." if r.barber_stock() == 0 else ""
			return _page("sal", "%d bottles of Canadian rye, wrapped in yesterday's Tribune. %s.%s" % [k, cost, tail], [], {"bought": k})
		"news":
			var talk := _talk_line(r.gossip("sal"))
			if talk == "":
				talk = "A barber hears everything, and tonight everything is nothing."
			if r.memory.recent("sal", "heard_threat", r.night, 3) > 0:
				talk += " And you, be gentle in my shop, eh? People talk."
			return _page("sal", talk)
	return {}


## What someone tells Danny about a piece of talk ("" when none).
func _talk_line(t: Dictionary) -> String:
	if t.is_empty():
		return ""
	var where := rackets.town.get_business(t.business).name if t.business != "" and rackets.town.get_business(t.business) != null else ""
	match t.kind:
		"short":
			return "Word is the truck came half empty at %s. Couldn't pay the driver." % where if where != "Novak's Grocery" \
				else "Word is Novak's truck came half empty. The man couldn't pay the driver."
		"threat":
			return "Word is you were rough with them at %s." % where
		"favour":
			return "Word is you helped out at %s. Decent of you." % where
		"lie":
			return "Word is Rourke caught somebody short-changing him. Somebody, Dimes."
	return ""


# ------------------------------------------------------------------ Mr. Novak, the grocer

func _novak(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var g := r.town.get_business("grocery")
	match step:
		"hello":
			if r.has_paid("grocery"):
				var again := "You again? I paid! There is nothing left in the till, look for yourself." if r.paid.grocery == "asked" \
					else "Please. I have nothing more. Please go."
				return _page("novak", again, [{"id": "apples", "text": "Just an apple, Mr. Novak."}])
			var att := r.memory.attitude("novak", r.night)
			var hello := "We're closing. Oh. It's you."
			if att.fear >= 4.0:
				hello = "Please. Not again. Not the shelves again."
			elif att.goodwill >= 2.0:
				hello = "Mr. Mercer! Come in, come in. I don't forget what you did."
			if g.missed_delivery > 0:
				hello = "Look at these shelves. The truck came half empty; I could not pay the driver."
			var opts := [{"id": "protection", "text": "It's Friday somewhere, Mr. Novak. Protection."}]
			if r.loans.has("novak"):
				opts.append({"id": "repay", "text": "About that loan, Mr. Novak."})
			elif r.shortfall_for_truck("grocery") > 0 or g.missed_delivery > 0:
				var lend := _loan_amount()
				if lend > 0 and r.money >= lend:
					opts.append({"id": "lend", "text": "I could lend you %s for the truck." % Rackets.dollars(lend)})
			opts.append({"id": "apples", "text": "Just an apple."})
			return _page("novak", hello, opts)
		"lend":
			var amount := _loan_amount()
			if r.lend("grocery", amount) == 0:
				return _page("novak", "No, no. I cannot take it.")
			return _page("novak", "You would do that? %s... I pay you back %s in two nights, with something for your trouble. I promise." % [
				Rackets.dollars(amount), Rackets.dollars(int(r.loans.novak.owed))], [], {"lent": amount})
		"repay":
			if not r.loans.has("novak"):
				return _page("novak", "We are square, Mr. Mercer. Thank you again.")
			var back := r.collect_loan("novak")
			if back == 0:
				return _page("novak", "Not yet. If I pay you tonight, the truck does not come. Tomorrow, I swear it.")
			if r.loans.has("novak"):
				return _page("novak", "Here, %s of it. The rest when the till allows." % Rackets.dollars(back), [], {"repaid": back})
			return _page("novak", "%s, all of it, as I said. You are an honest crook, Mr. Mercer." % Rackets.dollars(back), [], {"repaid": back})
		"protection":
			if r.has_paid("grocery"):
				return _page("novak", "I paid already tonight!")
			return _page("novak", "Again? Business is terrible. Nobody has money, the Depression...", [
				{"id": "ask", "text": "Everybody's got troubles. Pay up and you won't have mine."},
				{"id": "lean", "text": "(Sweep a row of tins off the shelf.)" if not context.get("gun_drawn", false) else "(Show him the .45.)"},
			])
		"ask":
			if r.has_paid("grocery"):
				return _page("novak", "I paid already tonight!")
			var got := r.collect("grocery", false)
			if got == 0:
				return _page("novak", "I have nothing. If I pay you, the truck does not come tomorrow, and then I have nothing forever.", [], {"paid": 0})
			if got < g.protection:
				return _page("novak", "%s. That is all; the rest is for the driver in the morning." % Rackets.dollars(got), [], {"paid": got})
			return _page("novak", "Here. %s. My wife will kill me. Same as always, yes? Same as always." % Rackets.dollars(got), [], {"paid": got})
		"lean":
			if r.has_paid("grocery"):
				return _page("novak", "I paid already tonight!")
			var grateful: bool = r.memory.attitude("novak", r.night).goodwill >= 2.0
			var got2 := r.collect("grocery", true)
			if got2 == 0:
				return _page("novak", "Take what? The till is empty! Look!\n(His eyes keep going to the door.)", [], {"paid": 0, "police": not grateful})
			if grateful:
				return _page("novak", "%s. After what you did for me... take it. I say nothing to nobody." % Rackets.dollars(got2), [], {"paid": got2})
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
			if r.eddie().stock <= 0:
				return _page("eddie", "Crate's empty. My fella brings a box a day; come back tomorrow night.")
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


# ------------------------------------------------------------------ Rourke, at his corner table in the Copper Owl

func _rourke(step: String, _context: Dictionary) -> Dictionary:
	var r := rackets
	var b := r.boss
	var want := b.expected + b.rye_end()
	var D := Rackets.dollars
	match step:
		"hello":
			if b.settled and b.arrears == 0:
				return _page("rourke", "We're square for tonight, Dimes. Go earn.", [{"id": "news", "text": "How's business, Mr. Rourke?"}])
			var line := ""
			match b.mood():
				"warm":
					line = "Danny boy. Sit down. You got something for me?"
				"cool":
					line = "Dimes. You got my envelope?"
				"cold":
					line = "You're behind, Danny. I'm a patient man, but patience costs money."
				_:
					line = "Not one more bottle of yours goes through Augie's bar till we're square. My money."
			if r.memory.recent("rourke", "lie", r.night, 4) > 0 and not b.settled:
				line = "Dimes. I count twice now, thanks to you. " + line
			elif r.memory.recent("rourke", "broken_promise", r.night, 2) > 0 and not b.settled:
				line = "You said tomorrow, Dimes. It's tomorrow. " + line
			if b.settled:
				line = "You still owe me %s, Dimes." % D.call(b.arrears)
			else:
				line += " I make it %s tonight" % D.call(want)
				line += ", with my end of the rye you're running through my club." if b.rye_end() > 0 else "."
			var opts := []
			if r.held > 0 or r.money >= want:
				opts.append({"id": "envelope", "text": "Here's your envelope."})
			opts.append({"id": "later", "text": "Not tonight, Mr. Rourke. I'll have it tomorrow."})
			opts.append({"id": "news", "text": "How's business, Mr. Rourke?"})
			return _page("rourke", line, opts)
		"envelope":
			var opts2 := []
			var keep := (r.held / 2) / 50 * 50
			if r.held >= want:
				opts2.append({"id": "hand_all", "text": "All of it: %s." % D.call(r.held)})
				if r.money >= r.held + 500:
					opts2.append({"id": "extra", "text": "All of it, and %s extra for your trouble." % D.call(500)})
			else:
				if r.held > 0:
					opts2.append({"id": "thin", "text": "It was a thin night. %s is all of it." % D.call(r.held)})
				if r.money >= want:
					opts2.append({"id": "top_up", "text": "Make it the full %s, out of my own pocket." % D.call(want)})
			if keep > 0:
				opts2.append({"id": "skim", "text": "Say it was a thin night: hand him %s, keep %s." % [D.call(r.held - keep), D.call(keep)]})
			return _page("rourke", "Let's see it.", opts2)
		"hand_all":
			return _rourke_verdict(r.pay_boss(r.held), "")
		"extra":
			return _rourke_verdict(r.pay_boss(r.held + 500), "")
		"thin":
			return _rourke_verdict(r.pay_boss(r.held, "bad_business"), "thin")
		"top_up":
			return _rourke_verdict(r.pay_boss(want), "")
		"skim":
			var keep2 := (r.held / 2) / 50 * 50
			return _rourke_verdict(r.pay_boss(r.held - keep2, "bad_business"), "thin")
		"later":
			var out := r.pay_boss(0)
			r.promise_boss()
			var line2 := "Tomorrow, then. %s, and don't make me come looking for you." % D.call(out.owed)
			if b.ban:
				line2 += " Till then Augie don't buy so much as a bottle off you."
			return _page("rourke", line2, [], {"boss": out, "promise": "rourke"})
		"news":
			var bits := []
			if b.belief.get("copper_owl", "good") != "good":
				bits.append("Augie's cellar is running dry and the swells notice.")
			if b.belief.get("grocery", "good") != "good":
				bits.append("I hear the grocer's struggling.")
			for h in b.heard:
				if String(h.text).begins_with("caught"):
					bits.append("And I hear things about you, Dimes. Don't make me hear more.")
					break
			if bits.is_empty():
				bits.append("Quiet. Quiet is good. Quiet means everybody pays.")
			var opts3 := []
			if b.trust >= 75 and b.commission < 30:
				opts3.append({"id": "my_end", "text": "About my end, Mr. Rourke..."})
			return _page("rourke", " ".join(bits), opts3)
		"my_end":
			if b.trust >= 75 and b.commission < 30:
				b.commission += 5
				return _page("rourke", "You've been straight with me. %d percent. Earn it." % b.commission)
			return _page("rourke", "Your end is what I say it is.")
	return {}


func _rourke_verdict(out: Dictionary, claim: String) -> Dictionary:
	var r := rackets
	var b := r.boss
	var D := Rackets.dollars
	var line := ""
	if out.caught:
		line = "Thin, is it? Augie tells me different. You're into me for %s, Dimes, and from now on I count twice." % D.call(out.owed)
	elif out.accepted and claim == "thin":
		line = "Yeah, I heard. Times are hard. All right, this once."
	elif out.accepted:
		line = "That's the way."
	elif claim == "thin":
		line = "Thin? Don't feed me lines. That's %s on the slate." % D.call(out.owed)
	else:
		line = "You're short, Danny. %s goes on the slate." % D.call(out.owed)
	if out.cut > 0:
		line += " Here's your end: %s." % D.call(out.cut)
	if b.ban:
		line += " And Augie don't buy another bottle off you till we're square."
	elif b.commission < Boss.COMMISSION:
		line += " Till you're straight with me, your end's half."
	return _page("rourke", line, [], {"boss": out})


## What Novak needs for tomorrow's truck, in whole dollars (at least $1).
func _loan_amount() -> int:
	var need := rackets.shortfall_for_truck("grocery")
	if need <= 0:
		need = rackets.town.get_business("grocery").missed_delivery * rackets.town.get_business("grocery").supply_cost
	return int(ceil(need / 100.0)) * 100 if need > 0 else 0
