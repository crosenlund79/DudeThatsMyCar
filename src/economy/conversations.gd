class_name Conversations
extends RefCounted
## What the people of the Riverside Ward say, as short pages with numbered
## answers (pure, no scene). Each page is
##   {speaker, text, options: [{id, text}], effects: {}}
## and an empty page ends the conversation. The money side lives in Rackets;
## effects ask the game for anything outside it ({"police": true}: someone
## runs for the copper once you have gone, {"rounds": n}: rounds for the gun).
## `context` describes the moment: {"gun_drawn": bool, "spare": int rounds
## carried, "time": "4:10 AM", "late": bool (time to go home), "first_meeting":
## bool (M006: Danny has not met them yet)}.
## M006: a page may carry "voice": [line ids] (VoiceLines) - its recorded
## words, which are then also its text. Meeting someone with a recorded
## greeting for the first time opens on that greeting, then their usual page.

const NAMES := {"augie": "Augie", "sal": "Sal", "novak": "Mr. Novak", "lindqvist": "Mr. Lindqvist", "eddie": "Eddie",
	"rourke": "Rourke", "bird": "The Bird", "lefty": "Lefty Moran", "pettibone": "Doc Pettibone", "bed": "Home",
	"dutch": "Dutch", "feeney": "Mr. Feeney", "irv": "Irv Feldman", "red": "Red Gallagher", "pete": "Lucky Pete",
	"moe": "Moe Brandt", "croupier": "Leo Varga", "union_board": "The noticeboard",
	"heeler": "The precinct captain", "doran_photos": "The photographs", "doran_desk": "The alderman's desk",
	"nightclerk": "The night clerk", "city_board": "The notices", "city_stairs": "The stairs", "city_records": "The records",
	"steward": "The steward", "regulars_portrait": "The portrait", "quilty": "Ald. Quilty", "quilty_map": "The ward map",
	"leon": "Leon Sobczak", "dispatch_board": "The dispatch board", "walt": "Walt Haney", "held_crates": "The crates",
	"mayor_gate": "At the gate", "bird_scene": "The Bird"}

## M012: things in a room to look at, each a narrated page (nothing changes hands).
const READS := {
	"doran_photos": "Doran shaking hands with a fellow in a silk hat outside the Stockyards. Doran cutting the ribbon on the new "
		+ "comfort station in Halloran Park. Doran at the ward picnic in his shirtsleeves, a beer in each fist, kids everywhere. "
		+ "In every one he's looking at the camera, never at the man beside him.",
	"doran_desk": "A blotter, a fountain pen, a stack of letters. A widow asking after her pension. A contractor thanking the "
		+ "alderman for his understanding in the matter of the Garrity Street sewer. A list of names in pencil headed STREETS & "
		+ "SANITATION - SPRING, some ticked, some crossed through. The drawer's locked. You leave it that way.",
	"city_board": "Notices behind glass: a tax sale of lots on Foundry Street; the Board of Health on milk; a hundred dollars "
		+ "for information on the Garfield Park fire; the ward committeemen for the spring primary in tidy columns, Doran's "
		+ "name and Quilty's among them. Somebody has given the Mayor a moustache.",
	"city_stairs": "A velvet rope on brass posts and a card: OFFICE OF THE MAYOR - BY APPOINTMENT. The night clerk watches you "
		+ "read it. Somewhere up there a typewriter is going, at this hour.",
	"city_records": "Births, deaths and building permits in calf-bound volumes, the ward rolls on the bottom shelf. Front "
		+ "Street, 1931, is back on the shelf the wrong way up - somebody had it out lately and didn't care who knew.",
	"regulars_portrait": "Old Mike Halloran in oils, the man the square is named for: alderman for thirty years, dead for ten. "
		+ "The brass plate says FRIEND OF THE WORKING MAN. The painter has given him the eyes of a man counting votes.",
	"quilty_map": "The Riverside Ward in red pencil, precinct by precinct. Every block has names written on it, and most of "
		+ "the names have a tick beside them. The Copper Owl's block has a star.",
	"dispatch_board": "Chalked in a quick hand: car numbers, bays and times. CAR 4471 - BAY 3 - TANNERY HIDES - 10 PM. "
		+ "CAR 2210 - BAY 1 - EMPTY. A Chicago & North Western schedule pinned beside it, thumbed grey.",
	"held_crates": "A dozen crates under a tarpaulin, stencilled NBF, a waybill tag on the corner. They look like they've "
		+ "been waiting a while.",
}


## M012: a thing to look at - and while Leon's freight is held, what the
## yards' boards and the crates themselves give away.
func _read(who: String) -> Dictionary:
	var f := rackets.freight
	var text: String = READS[who]
	var effects := {}
	match who:
		"dispatch_board":
			if f.stage != FreightJob.Stage.NOT_OFFERED and not f.crates_out:
				text += " At the bottom, underlined twice: HARTMANN'S - 12 CR - RADIO CABINETS - %s TRUCK. HELD IN SHED??" \
					% FreightJob._clock(f.deadline).to_upper()
				if f.is_open():
					f.learn("consignee")
					effects = {"freight": "learned"}
		"held_crates":
			if f.crates_out:
				text = "Just the marks on the concrete where a dozen crates stood, and a scrap of tarpaulin."
			else:
				text = "A dozen crates under a tarpaulin, stencilled NBF. The waybill tag: HARTMANN'S DEPT. STORE, STATE ST. - 12 CS. " \
					+ "RADIO CABINETS - FRAGILE. Somebody has chalked on the top crate: NOT TILL WE'RE PAID."
				if f.is_open():
					f.learn("consignee")
					effects = {"freight": "learned"}
	return _told(who, text, [{"id": "bye", "text": "Leave it be."}], effects)


## M012: whether E at this spot reads something rather than talking to someone.
static func is_readable(id: String) -> bool:
	return id == "union_board" or READS.has(id)

var rackets: Rackets


func _init(p_rackets: Rackets) -> void:
	rackets = p_rackets


func speaker(who: String) -> String:
	return NAMES.get(who, who.capitalize())


## Who greets Danny with a recording the first time they meet, and his reply.
const GREETINGS := {
	"augie": ["augie_greeting", "Pleased to meet you, Augie. I'm Danny Mercer."],
	"rourke": ["rourke_greeting", "Good to be back, Mr. Rourke."],
	"eddie": ["eddie_greeting", "No hammer. Something with a little more bang."],
}


## The first page when you walk up to someone and press E.
## M012: `context.callout` - Danny answers someone who called out to him: they
## open on what they called him over for, then their usual choices.
func open(who: String, context: Dictionary = {}) -> Dictionary:
	if context.get("first_meeting", false) and GREETINGS.has(who):
		var g: Array = GREETINGS[who]
		var page := _page(who, VoiceLines.text(g[0]), [{"id": "hello", "text": g[1]}])
		page["voice"] = [g[0]]
		return page
	var hello := _say(who, "hello", context)
	var called := String(context.get("callout", ""))
	if called != "" and Callouts.LINES.has(called) and not hello.is_empty():
		var line: Dictionary = Callouts.LINES[called]
		hello["text"] = line.follow
		hello["delivery"] = line.tag  # for the actor, never shown
	return hello


## The recorded greeting someone has for a first meeting ("" for none).
static func greeting_line(who: String) -> String:
	if who == "bird":
		return "bird_greeting"
	return GREETINGS[who][0] if GREETINGS.has(who) else ""


## The page after choosing an answer (an empty page: the talk is over).
func choose(who: String, option: String, context: Dictionary = {}) -> Dictionary:
	if option == "bye":
		return {}
	return _say(who, option, context)


func _say(who: String, step: String, context: Dictionary) -> Dictionary:
	# M015: somebody who keeps a place of business won't do it with a gun out
	var gun := int(context.get("gun_out", 0))
	if step == "hello" and gun > 0 and GunSight.SHY.has(who):
		if rackets.memory.recent(who, "gun_shown", rackets.night, 1) == 0:
			rackets.memory.remember(who, "gun_shown", rackets.night)
		return _page(who, GunSight.line(who, gun), [{"id": "holster", "text": "(Put it away.)"}])
	if step == "holster":
		var hello := _say(who, "hello", context.merged({"gun_out": 0}, true))
		if hello.is_empty():
			return hello
		var fx: Dictionary = hello.get("effects", {})
		fx["holster"] = true
		hello["effects"] = fx
		return hello
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
		"bird":
			return _bird(step, context)
		"bird_scene":
			return _bird_scene(step)
		"lefty":
			return _lefty(step, context)
		"pettibone":
			return _vet(step, context)
		"incident":
			return _incident(step, context)
		"dutch":
			var dp := _dutch(step, context)
			if step == "hello" and rackets.freight.is_open() and not rackets.freight.learned.has("docked") and not dp.is_empty():
				(dp.options as Array).insert(0, {"id": "freight_ask", "text": "Know anything about the North Branch shed?"})
			if step == "freight_ask":
				rackets.freight.learn("docked")
				return _told("dutch", "\"Walt Haney's boys sat right where you're standing, sore as boils. Company docked the "
					+ "whole gang six bucks for a crate Mickey Duffy dropped. Walt says nothing leaves that shed till it's put "
					+ "back.\" He pours you a coffee you didn't ask for.", [], {"freight": "learned"})
			return dp
		"feeney":
			return _feeney(step, context)
		"bed":
			return _bed(step, context)
		"union_board":
			return _union_board(step)
		"heeler":
			return _heeler(step, context)
		"nightclerk":
			return _nightclerk(step, context)
		"steward":
			return _steward(step)
		"quilty":
			return _quilty(step, context)
		"leon":
			return _leon(step, context)
		"walt":
			return _walt(step, context)
		"mayor_gate":
			return _mayor_gate(step)
	if READS.has(who) and step == "hello":
		return _read(who)
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
		"job_deal":
			return "Word is you sat down with Lefty Moran and talked him off the Swede's back. Talked! In this ward."
		"job_backed_down":
			return "Word is you leaned on Lefty Moran and he folded like a deck chair."
		"job_beaten":
			return "Word is you beat Lefty Moran with your bare hands on Pruitt Street. With your hands, Dimes."
		"job_killed":
			return "Word is Lefty Moran's in the Morgue. And the North Side's asking who put him there."
		"job_lost":
			return "Word is Lefty Moran gave you a hiding. You might want to see the Doc."
		"job_returned":
			return "Word is you gave the Swede his money back. Nobody gives anything back. People are talking."
		"job_still":
			return "Word is the Swede's still paying the North Side. Thought you'd want to know."
		# M009: Danny's own work, as the ward tells it
		"crate_run":
			return "Word is you're hauling crates up from the yards for Dutch. Novak's shelves never looked so good."
		"crate_dropped":
			return "Word is Dutch down at the yards is sore at you. Something about a crate that went for a ride."
		"reel_returned":
			return "Word is you saved the late show at the Bijou over in Halloran Square. Feeney's telling the whole square."
		"reel_cancelled":
			return "Word is the Bijou in Halloran Square had to cancel its late show. The reel never came. Twenty-two refunds."
		# M012: North Branch Freight
		"freight_paid":
			return "Word is you paid a freight shed gang their docked wages out of your own pocket. Walt Haney's buying the rounds."
		"freight_squared":
			return "Word is you talked the North Branch dispatcher into giving his shed gang back their six bucks. Talked a company man out of money, Dimes."
		"freight_leaned":
			return "Word is you showed Walt Haney at the North Branch shed something shiny, and twelve crates got loaded in ten minutes."
		"freight_beaten":
			return "Word is you went a few rounds with the North Branch shed foreman. The freight went out on time, anyhow."
		"freight_lapsed":
			return "Word is the North Branch dispatcher was counting on you, and paid his shed gang out of his own pocket in the end."
		# M010: Rosie's Café
		"cafe_blast":
			return "Word is somebody blew Vince Duggan's Packard sky-high outside Rosie's in Halloran Square. Duggan was inside with his coffee. Never spilled a drop, they say."
		"cafe_seen":
			return "Word is a copper got a look at somebody by Duggan's car before it went up. Somebody in a good hat, Dimes."
		# M009: the city's own incidents, as the ward tells them
		"street_argument_blows":
			return "Word is two fellas came to blows %s. Over a dented fender, if you can believe it." % t.text
		"street_argument_broken_up":
			return "Word is you broke up a scrap %s. Decent of you." % t.text
		"street_argument_scattered":
			return "Word is you put the fear of God into two fellas %s." % t.text
		"street_exchange_robbed":
			return "Word is somebody stuck up a little handoff %s and walked off with the lot. Somebody in a good hat." % t.text
		"street_exchange_spoiled":
			return "Word is you spoiled somebody's little transaction %s. They won't thank you for it." % t.text
		"street_exchange_hushed":
			return "Word is you took a cut of some business %s. Nice work if you can get it." % t.text
		"street_exchange_shooting", "street_argument_shooting", "street_stop_shooting":
			return "Word is there was shooting %s. Nobody saw nothing, naturally." % t.text
		"street_stop_taken_in":
			return "Word is the copper took a fella in %s. Didn't go quietly." % t.text
		"street_stop_vouched":
			return "Word is you stood up for a fella the copper stopped %s. The copper didn't care for it." % t.text
		"street_stop_bribed":
			return "Word is the copper %s takes a dollar to look the other way. Somebody tried it." % t.text
		"shot":
			return "Word is you put a bullet in %s. People are scared of you, Dimes. Scared ain't the same as loyal." % speaker(t.text)
		# M015: Lefty Moran's speedster
		"lefty_car":
			return "Word is somebody drove off in Lefty Moran's speedster. Lefty's asking around, Dimes - and he's asking about you."
		"lefty_car_back":
			return "Word is Lefty's speedster turned up back on his kerb, not a scratch on her. Lefty's cooled off some."
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
				return _page("novak", again, _crate_option(context) + [{"id": "apples", "text": "Just an apple, Mr. Novak."}])
			var att := r.memory.attitude("novak", r.night)
			var hello := "We're closing. Oh. It's you."
			if att.fear >= 4.0:
				hello = "Please. Not again. Not the shelves again."
			elif att.goodwill >= 2.0:
				hello = "Mr. Mercer! Come in, come in. I don't forget what you did."
			if g.missed_delivery > 0:
				hello = "Look at these shelves. The truck came half empty; I could not pay the driver."
			var opts := _crate_option(context) + [{"id": "protection", "text": "It's Friday somewhere, Mr. Novak. Protection."}]
			if r.loans.has("novak"):
				opts.append({"id": "repay", "text": "About that loan, Mr. Novak."})
			elif r.shortfall_for_truck("grocery") > 0 or g.missed_delivery > 0:
				var lend := _loan_amount()
				if lend > 0 and r.money >= lend:
					opts.append({"id": "lend", "text": "I could lend you %s for the truck." % Rackets.dollars(lend)})
			opts.append({"id": "apples", "text": "Just an apple."})
			return _page("novak", hello, opts)
		"crate":
			if r.opportunities.crate != "loaded" or not context.get("crate_outside", false):
				return _page("novak", "A crate? I don't see no crate, Mr. Mercer. Bring it round the side, not in here.")
			var pay := mini(Opportunities.CRATE_PAY, g.cash)
			var line := "\"From Dutch? Peaches! God bless the Dutchman.\" You heave it into his back room between you, and Novak counts %s into your hand." % Rackets.dollars(pay)
			if pay < Opportunities.CRATE_PAY:
				line = "\"From Dutch? Peaches...\" You heave it into his back room. \"%s is all the till has, Mr. Mercer. Dutch will understand.\"" % Rackets.dollars(pay)
			return _told("novak", line, [], {"opportunity": "deliver_crate"})
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
	var job := rackets.job
	match step:
		"hello":
			var opts := [
				{"id": "back", "text": "Is Eddie in the back?"},
				{"id": "rope", "text": "Just looking at the rope."},
			]
			# M007: Rourke's job - who has been squeezing him, and his money
			if job.stage == RourkeJob.Stage.ACCEPTED and not job.knows_culprit():
				opts.push_front({"id": "job_ask", "text": JobLines.answer("lindqvist_ask")})
			if job.recovered > 0 and job.money_went == "" and rackets.money >= job.recovered:
				opts.push_front({"id": "job_return", "text": JobLines.answer("lindqvist_return") % Rackets.dollars(job.recovered)})
			if job.outcome != "":
				var said: String = {"deal": "lindqvist_deal", "backed_down": "lindqvist_rid", "beaten": "lindqvist_rid",
					"killed": "lindqvist_killed"}[job.outcome]
				return _job_page(said, opts)
			if job.knows_culprit() and job.fight_lost_night >= 0:
				return _job_page("lindqvist_waiting", opts)
			return _page("lindqvist", "Lindqvist Hardware. Nails, paint, rope. Something else, maybe?", opts)
		"job_ask":
			job.learn("culprit")
			return _job_page("lindqvist_tells", [], {"job": "learned"})
		"job_return":
			job.return_money(rackets)
			return _job_page("lindqvist_returned", [], {"job": "returned"})
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
			var eopts := [{"id": "wares", "text": "Let's see what you've got."}]
			if r.loan.out:
				eopts.append({"id": "give_back", "text": "Here's your Thompson back. Not a scratch on her."})
			if rackets.job.knows_culprit() and not rackets.job.learned.has("tip") and rackets.job.outcome == "":
				eopts.append({"id": "job_lefty", "text": JobLines.answer("eddie_lefty")})
			if r.loan.overdue(r.night):
				return _page("eddie", "Dimes. %d nights you've had my chopper. I got customers asking, and I got a deposit that ain't worth the trouble. Bring her home." % (r.night - r.loan.since), eopts)
			return _page("eddie", "Well, if it ain't the Copper Owl's errand boy. Pull up a chair. Don't touch the crate.", eopts)
		"give_back":
			if not r.loan.out:
				return _page("eddie", "Give back what? You been drinking Sal's rye again?")
			var back := r.return_thompson()
			return _page("eddie", "Let's see... she's been working. Fine - what you do on your own time is your business. %s back, I keep the buck for my trouble." % Rackets.dollars(back), [], {"thompson": "returned"})
		"job_lefty":
			rackets.job.learn("tip")
			return _job_page("eddie_tip", [], {"job": "tip"})
		"wares":
			var wares := [
				{"id": "ammo", "text": "A box of .45 rounds. (%s for %d)" % [price, r.rules.ammo_box]},
				{"id": "heavy", "text": "Got anything heavier?"},
			]
			if r.parcel_wanted and r.parcels == 0:
				wares.append({"id": "parcel", "text": "Rourke says you've got a parcel for me. (%s)" % Rackets.dollars(Rackets.PARCEL_PRICE)})
			var page := _page("eddie", VoiceLines.text("eddie_sales"), wares)
			page["voice"] = ["eddie_sales"]
			return page
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
			if r.loan.out:
				return _page("eddie", "You got the heaviest thing I own under your coat already.")
			return _page("eddie", "A Thompson costs more than you make in a year, kid. I don't sell her. But I rent her out, to fellas I know. Five bucks down. Bring her back and you get four of it. Two spare sticks of twenty go with her, and she don't come back empty-handed into my shop with my name on her - understood?", [
				{"id": "borrow", "text": "I'll take her. (%s deposit)" % Rackets.dollars(GunLoan.DEPOSIT)},
				{"id": "bye", "text": "Not tonight."},
			])
		"borrow":
			if r.loan.out:
				return _page("eddie", "You got her already.")
			if not r.borrow_thompson():
				return _page("eddie", "Five bucks down, I said. Come back when your pockets jingle.")
			return _page("eddie", "There she is. Twenty in the stick, forty more in your coat. She climbs when you hold the trigger, so short bursts. And Dimes - she's a loan. She comes back to me. (Tab switches between the Thompson and your .45.)", [], {"thompson": "lent"})
		"parcel":
			if not r.parcel_wanted:
				return _page("eddie", "Parcel? I don't know nothing about any parcel.")
			if r.parcels > 0:
				return _page("eddie", "You got it already. Don't make me nervous.")
			if not r.buy_parcel():
				return _page("eddie", "%s, cash. I don't give credit on these." % Rackets.dollars(Rackets.PARCEL_PRICE))
			return _page("eddie", "Here. Brown paper and string, nice and plain. Don't shake it, don't drop it, don't open it and don't ask me what's in it. You never got it here. %s." % Rackets.dollars(Rackets.PARCEL_PRICE), [], {"parcel": 1})
	return {}


# ------------------------------------------------------------------ the Bird, at her microphone in the Copper Owl

## `context.interrupted`: Danny has just stopped her song (her complaint is
## said in her voice); `context.first_meeting`: she has not introduced herself
## yet (her greeting follows as a page of its own, after the complaint).
func _bird(step: String, context: Dictionary) -> Dictionary:
	var chat := [
		{"id": "secrets", "text": "Heard any good secrets lately?"},
		{"id": "song", "text": "That song. Who's it for?"},
		{"id": "bye", "text": "Go on, finish your number."},
	]
	var page := {}
	match step:
		"hello":
			if context.get("interrupted", false):
				var opts: Array = [{"id": "who", "text": "Sorry, sweetheart. Do I know you?"}] if context.get("first_meeting", false) else chat
				page = _page("bird", VoiceLines.text("bird_interrupted"), opts)
				page["voice"] = ["bird_interrupted"]
				return page
			if context.get("first_meeting", false):
				return _bird("who", context)
			if context.get("done", false):  # M012: her last song is sung
				chat = [chat[0], {"id": "bye", "text": "Goodnight, Bird."}]
			var after := {"truth": "My honest man. Make it quick, the band won't wait.",
				"kind": "The gentleman who hears nothing worth repeating. What'll it be?",
				"guard": "Know me any better yet, Mercer?",
				"silent": "You again. Still saving your words?"}  # M012: what he said after her last song
			var plain := "The set's over, Mercer. What is it?" if context.get("done", false) else "Make it quick, Mercer. The band won't wait all night."
			return _page("bird", after.get(rackets.bird_scene, plain), chat)
		"who":
			page = _page("bird", VoiceLines.text("bird_greeting"), chat)
			page["voice"] = ["bird_greeting"]
			return page
		"secrets":
			var heard := _talk_line(rackets.gossip("augie"))
			if heard != "":
				return _page("bird", "Honey, from up there you hear everything. " + heard, chat.slice(1))
			return _page("bird", "Secrets cost more than a drink, Mercer. Come back when you're buying the bottle.", chat.slice(1))
		"song":
			return _page("bird", "'Leave the Lights Low.' It's for whoever's still sitting there at closing time. Most nights that's Rourke.",
				[chat[0], chat[2]])
	return {}


# ------------------------------------------------------------------ Lefty Moran, outside Doyle's Garage (M006)

func _lefty(step: String, context: Dictionary) -> Dictionary:
	var job := rackets.job
	var night: int = context.get("night", rackets.night)
	match step:
		"hello":
			# M015: his car (gone, or back after Danny took it) comes first
			var car_line := _lefty_car_line()
			if car_line != "":
				return _page("lefty", car_line, [{"id": "bye", "text": "I'll keep an eye out."}])
			# M007: once Rourke's job has brought Danny to him
			if job.outcome != "" and job.outcome != "killed":
				return _job_page("lefty_after_" + job.outcome)
			if job.can_confront():
				return _job_page("lefty_after_lost" if job.fight_lost_night >= 0 else "lefty_open",
					_lefty_choices(job, night))
			return _page("lefty", "Keep walking, pal. This corner's spoken for.", [
				{"id": "who", "text": "Spoken for by who?"},
				{"id": "bye", "text": "Sure. Nice hat."},
			])
		"who":
			return _page("lefty", "Lefty Moran. North Side. I don't take Rourke's money and I don't drink in his club. " +
				"You want trouble, Mercer, you know where the garage is.")
		"job_talk":
			if not job.lefty_talks():
				return _job_page("lefty_no_talk", _lefty_choices(job, night, false))
			return _job_page("lefty_why", [
				{"id": "job_deal", "text": JobLines.answer("lefty_deal")},
				{"id": "job_money", "text": JobLines.answer("lefty_money")},
			])
		"job_deal":
			job.record("talk", "deal", night)
			job.resolve("deal", rackets)
			return _job_page("lefty_deal", [], {"job": "settled"})
		"job_money":
			job.record("talk", "refused", night)
			return _job_page("lefty_no_money", _lefty_choices(job, night, false))
		"job_threaten":
			if job.threat_works(context):
				job.record("threat", "worked", night)
				job.resolve("backed_down", rackets)
				return _job_page("lefty_folds", [], {"job": "settled"})
			job.bluff_called_night = night
			job.record("threat", "called", night)
			var hurt: bool = int(context.get("danny_worst", 0)) >= BodyCondition.Level.WOUNDED
			return _job_page("lefty_calls_bluff_hurt" if hurt else "lefty_calls_bluff", _lefty_choices(job, night, false))
		"job_fight":
			if not job.lefty_fights(night):
				return _job_page("lefty_no_fight", _lefty_choices(job, night, false))
			return _job_page("lefty_fight", [{"id": "bye", "text": "(Raise your fists.)"}], {"fight": "lefty"})
		# after the fistfight (main sends these when the dial is done)
		"job_fight_won":
			job.record("fight", "won", night)
			job.resolve("beaten", rackets)
			return _job_page("lefty_beaten", [], {"job": "settled"})
		"job_fight_lost":
			job.lost_fight(rackets)
			return _job_page("lefty_won")
	return {}


# ------------------------------------------------------------------ M009: the city's own incidents

## Danny steps into one of the city's incidents. context.incident_kind:
## "argument", "exchange" or "stop"; gun_drawn; money (cents).
func _incident(step: String, context: Dictionary) -> Dictionary:
	var kind: String = context.get("incident_kind", "")
	var gun: bool = context.get("gun_drawn", false)
	match kind:
		"argument":
			match step:
				"hello":
					return _incident_page("Two men at the kerb", "\"Stay out of it, mister. This bum backed into my car.\"", [
						{"id": "calm", "text": "Easy, boys. Nobody needs the Doc tonight."},
						{"id": "lean", "text": "(Hand on the .45.) Beat it. The pair of you." if gun else "(Step between them.) Beat it. The pair of you."},
						{"id": "bye", "text": "(Leave them to it.)"}])
				"calm":
					return _incident_page("Two men at the kerb", "\"...Aw, he ain't worth it.\" They go their ways, still muttering.", [], {"incident": "calm"})
				"lean":
					return _incident_page("Two men at the kerb", "They take one look at you and go - fast, and in opposite directions.", [], {"incident": "lean"})
		"exchange":
			match step:
				"hello":
					var opts := [{"id": "see", "text": "What's in the package, fellas?"}, {"id": "cut", "text": "Nice night for business. Where's my cut?"}]
					if gun:
						opts.append({"id": "rob", "text": "(Show them the .45.) I'll take that."})
					opts.append({"id": "bye", "text": "Never mind me."})
					return _incident_page("Two men in the shadows", "\"Who's asking?\" The one with the package keeps it behind his back.", opts)
				"see":
					return _incident_page("Two men in the shadows", "\"Nothing for you, pal.\" They break it off and go, quick.", [], {"incident": "see"})
				"cut":
					return _incident_page("Two men in the shadows", "\"...Fine. Two bucks, and you never saw us.\" A folded pair of dollars.", [], {"incident": "cut"})
				"rob":
					if not gun:
						return _incident_page("Two men in the shadows", "\"Nothing for you, pal.\" They break it off and go, quick.", [], {"incident": "see"})
					return _incident_page("Two men in the shadows", "\"Easy with that thing!\" The package lands at your feet and they run.", [], {"incident": "rob"})
		"stop":
			match step:
				"hello":
					var stop_opts := [{"id": "vouch", "text": "He's with me, officer. He's done nothing."}]
					if int(context.get("money", 0)) >= STOP_BRIBE:
						stop_opts.append({"id": "bribe", "text": "(Fold a dollar into his hand.) Let the man go home."})
					stop_opts.append({"id": "bye", "text": "Sorry, officer. (Move along.)"})
					return _incident_page("The beat cop", "\"Move along, mister. This is police business.\"", stop_opts)
				"vouch":
					return _incident_page("The beat cop", "\"Is that so.\" He lets the man go - and takes a long, hard look at you.", [], {"incident": "vouch"})
				"bribe":
					return _incident_page("The beat cop", "The dollar disappears. \"...Go on home, the both of yous.\"", [], {"incident": "bribe"})
	return {}


const STOP_BRIBE := 100


# ------------------------------------------------------------------ M009: Dutch and Mr. Feeney

## Novak's answer when Dutch's crate is in a car out front.
func _crate_option(context: Dictionary) -> Array:
	if rackets.opportunities.crate == "loaded" and context.get("crate_outside", false):
		return [{"id": "crate", "text": "I've got a crate out front for you. From Dutch, at the yards."}]
	return []


## Dutch, at his night lunch counter on Foundry Street.
func _dutch(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var o := r.opportunities
	match step:
		"hello":
			var sore := r.memory.recent("dutch", "broken_promise", r.night, 4) > 0
			var good := r.memory.recent("dutch", "kept_promise", r.night, 6) > 0
			match o.crate:
				"waiting":
					var ask := "A big man in a grease-spotted apron wipes his hands. \"You got wheels, mister? I got a crate needs to go up to Novak's grocery in Riverside. Tinned goods, off a boxcar - don't ask which boxcar. Novak pays %s at his door. Before two, mind; he don't open after.\"" % Rackets.dollars(Opportunities.CRATE_PAY)
					if good:
						ask = "\"Mercer! Novak says you're reliable. Got another one for him - same deal, %s at his door, before two.\"" % Rackets.dollars(Opportunities.CRATE_PAY)
					elif sore:
						ask = "\"You. Last time my crate went for a ride round Riverside all night.\" He looks you over. \"...I got another. You want it, you deliver it this time. Before two.\""
					return _told("dutch", ask, [{"id": "take", "text": "I'll take it up."}, {"id": "what", "text": "What's really in it?"},
						{"id": "bye", "text": "Not tonight, Dutch."}])
				"taken":
					return _told("dutch", "\"It's there by the door. Bring a car up to the kerb and we'll heave it in the boot.\"")
				"loaded":
					return _told("dutch", "\"Go on, Novak's waiting. Back way, quiet like. Before two.\"")
				"delivered":
					return _told("dutch", "\"Novak telephoned the drugstore to say it came. Peaches all round. Coffee's on the house tonight.\"")
				"gone":
					return _told("dutch", "\"Too late, pal. My nephew took it up in the ice truck. Coffee's a nickel, pie's a dime.\"")
				"dropped":
					return _told("dutch", "\"My nephew had to go find my crate in Riverside at three in the morning. Don't come round here making promises.\"")
			if sore:
				return _told("dutch", "\"Coffee's a nickel. Crates I give to people who deliver them.\"")
			return _told("dutch", "\"Coffee's a nickel, pie's a dime. Nothing else tonight, mister.\"")
		"what":
			return _told("dutch", "\"Peaches. Mostly peaches. Some of 'em even say peaches on the tin.\"",
				[{"id": "take", "text": "Peaches it is. I'll take it."}, {"id": "bye", "text": "Not tonight."}])
		"take":
			if o.crate != "waiting":
				return _told("dutch", "\"Too late for that, pal.\"")
			return _told("dutch", "\"Good man. It's by the door. Bring a car up to the kerb here and we'll heave it in the boot.\"",
				[], {"opportunity": "take_crate"})
	return {}


## Mr. Feeney, who manages the Bijou on Marlowe Avenue in Halloran Square.
func _feeney(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var o := r.opportunities
	match step:
		"hello":
			var sore := r.memory.recent("feeney", "broken_promise", r.night, 4) > 0
			match o.reel:
				"lost":
					var ask := "A small man in a dinner jacket is wringing his hands under the marquee. \"The reel for the late show never came! The exchange's boy says he set the can down behind St. Brendan's, the dolt. I can't leave a full lobby. %s if it's in my hands before eleven.\"" % Rackets.dollars(Opportunities.REEL_PAY)
					if sore:
						ask = "\"You again. The exchange's boy has lost a reel again - behind St. Brendan's, again. I suppose you'll say you'll fetch it. Before eleven, %s.\"" % Rackets.dollars(Opportunities.REEL_PAY)
					return _told("feeney", ask, [{"id": "take", "text": "I'll find your reel."}, {"id": "bye", "text": "Not my line of work."}])
				"looking":
					return _told("feeney", "\"Behind St. Brendan's, he said. Eleven o'clock, mister. Eleven!\"")
				"found":
					return _told("feeney", "\"Is that...?\"", [{"id": "give", "text": "One reel, slightly dusty."}])
				"returned":
					return _told("feeney", "\"The late show's running. Listen to them laugh. Any night you like, mister, there's a seat for you.\"")
				"cancelled":
					var line := "\"No reel, no late show. Twenty-two refunds.\" He looks at you. \"Some help you were.\"" if o.reel_promised \
						else "\"No reel, no late show. Twenty-two refunds. I could weep.\""
					return _told("feeney", line)
			return _told("feeney", "\"Tonight at nine and eleven, 'Gentlemen of the Night'. Fifteen cents, mister, and worth every one.\"")
		"take":
			if o.reel != "lost":
				return _told("feeney", "\"Too late for that now.\"")
			return _told("feeney", "\"Bless you! Behind the church, he said. Before eleven!\"", [], {"opportunity": "take_reel"})
		"give":
			if o.reel != "found":
				return {}
			return _told("feeney", "Feeney clutches the can like a newborn. \"Saved! %s, and a seat any night you like.\" He hurries it up to the booth." % Rackets.dollars(Opportunities.REEL_PAY),
				[], {"opportunity": "return_reel"})
	return {}


func _incident_page(who: String, text: String, options: Array = [], effects: Dictionary = {}) -> Dictionary:
	var page := _told("incident", text, options, effects)
	page["speaker"] = who
	return page


## M009: a narrated page - what happens, the speech in quotes (shown as written).
func _told(who: String, text: String, options: Array = [], effects: Dictionary = {}) -> Dictionary:
	var page := _page(who, text, options, effects)
	page["narrated"] = true
	return page


## Danny's ways of settling it with Lefty (the talk, a threat, his fists, or leaving).
## M015: what Lefty says about his car when Danny walks up ("" when nothing).
func _lefty_car_line() -> String:
	var m := rackets.lefty_car
	if m.knows == "gone":
		return "Somebody took my car off this kerb. Black speedster, cream top - you can't miss her. You hear anything, Mercer, you tell me first."
	if m.knows == "danny" and m.returned and rackets.memory.recent("lefty", "returned_car", rackets.night, 2) > 0:
		return "My car's back on the kerb. Smartest thing you ever did, Mercer. Don't do it again."
	return ""


func _lefty_choices(job: RourkeJob, night: int, with_talk: bool = true) -> Array:
	var opts := []
	if with_talk:
		opts.append({"id": "job_talk", "text": JobLines.answer("lefty_confront") + " " + JobLines.answer("lefty_talk")})
	if job.bluff_called_night != night:
		opts.append({"id": "job_threaten", "text": JobLines.answer("lefty_threaten")})
	if job.lefty_fights(night):
		opts.append({"id": "job_fight", "text": JobLines.answer("lefty_fight")})
	return opts


# ------------------------------------------------------------------ Doc Pettibone, the vet on Pruitt Street (M006)

## `context.treatment`: what patching Danny up costs (cents; 0 = he is not
## hurt). Paying it heals him ({"heal": true}).
func _vet(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var price: int = context.get("treatment", 0)
	match step:
		"hello":
			if price <= 0:
				return _page("pettibone", "Dogs, cats, the odd dray horse - and fellas who can't go to County. " +
					"You look healthy as a horse, Mercer. Healthier than most of my horses.", [
					{"id": "horses", "text": "You really patch up gangsters, Doc?"},
				])
			return _page("pettibone", "Up on the table. Let's see what they did to you this time.", [
				{"id": "patch", "text": "Patch me up, Doc. (%s)" % Rackets.dollars(price)},
				{"id": "horses", "text": "You really patch up gangsters, Doc?"},
			])
		"patch":
			if price <= 0:
				return _page("pettibone", "Nothing to patch.")
			if r.money < price:
				return _page("pettibone", "Cash first, Mr. Mercer. Even the horses pay up front.")
			r.pay_doctor(price)
			return _page("pettibone", "Hold still... there. Same thing I tell a bulldog: no running for a week. " +
				"You won't listen either.", [], {"heal": true, "paid": price})
		"horses":
			return _page("pettibone", "A bullet's a bullet, son. Goes into a horse much the same as a hoodlum. " +
				"The horse holds still better.", [])
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


## M012: reading the shed gang's notice tells Danny why the freight is held.
func _union_learns() -> Dictionary:
	if rackets.freight.is_open() and not rackets.freight.learned.has("docked"):
		rackets.freight.learn("docked")
		return {"freight": "learned"}
	return {}


## M011: the noticeboard in the union hall - what is pinned up there tonight
## (the world as it is; nothing here is a job for Danny).
func _union_board(step: String) -> Dictionary:
	match step:
		"hello":
			return _told("union_board", "Shift lists for the North Branch Freight bays, smudged with coal dust. A typed notice: "
				+ "GENERAL MEETING, THURSDAY, 8 P.M. - ALL MEMBERS IN GOOD STANDING. Dues are fifty cents a week, payable at "
				+ "the office. A hand-lettered card: NO WORK FOR MEN WITHOUT A BOOK. A clipping from the Evening Courier about the "
				+ "new mayor's budget, with somebody's pencil all over it. A picnic at the Forest Preserve, if the weather holds."
				+ (" Pinned at the bottom, in pencil: SHED GANG, NORTH BRANCH FRT. - $6 DOCKED FOR ONE BROKEN CRATE. NOT ONE BOX "
				+ "MOVES TILL IT'S BACK. - W.H." if rackets.freight.is_open() else ""),
				[{"id": "bye", "text": "Leave it be."}], _union_learns())
	return {}


## M012: Alderman Doran's precinct captain, keeping the ward office's lamp lit
## (not a named man of the square: the alderman's people come and go).
func _heeler(step: String, context: Dictionary) -> Dictionary:
	match step:
		"hello":
			var hello := "Office is shut, friend. The alderman's back Tuesday. 'Course, if it's a job with the city, a box for "\
				+ "your mother or a cousin in the lockup, I'm the fella you want."
			if context.get("late", false):
				hello = "You're up late. So am I - forty men want twelve shovels with the street department, and every one of "\
					+ "'em swears his whole family votes."
			return _page("heeler", hello, [{"id": "ward", "text": "Who runs this ward, then?"},
				{"id": "list", "text": "Busy night?"}])
		"ward":
			return _page("heeler", "Martin J. Doran runs it, the way his father did. A turkey at Christmas, coal when it's cold, "
				+ "and everybody votes. You're Rourke's boy, ain't you? Mr. Rourke and the alderman understand each other. "
				+ "Let's all keep it that way.", [{"id": "list", "text": "What's keeping you up?"}])
		"list":
			return _page("heeler", "The spring list for Streets and Sanitation. Who gets a shovel and who gets a handshake. "
				+ "Some of these fellas even live in the ward.", [{"id": "ward", "text": "Who runs this ward, then?"}])
	return {}


## M012: City Hall's night clerk behind his brass grille.
func _nightclerk(step: String, context: Dictionary) -> Dictionary:
	match step:
		"hello":
			var hello := "City Hall's closed till nine, mister. The night window's for bail money for the night court, dog "\
				+ "licences and complaints about the streetcars. Which is it?"
			if context.get("late", false):
				hello = "This hour, mister? You're the third fella tonight come in asking for nobody in particular."
			return _page("nightclerk", hello, [{"id": "upstairs", "text": "Who's working upstairs this late?"},
				{"id": "streetcars", "text": "The streetcars."}])
		"upstairs":
			return _page("nightclerk", "The Mayor's office keeps its own hours. I keep the door. You'd want an appointment, "
				+ "and you'd want to be somebody.", [{"id": "streetcars", "text": "Then I'll complain about the streetcars."}])
		"streetcars":
			return _page("nightclerk", "Get in line. Third floor, Monday, on the green form - not the blue one, the blue one's "
				+ "for compliments. We don't get many.")
	return {}


## M012: the Regulars' Club's steward, who pours nothing these days.
func _steward(step: String) -> Dictionary:
	match step:
		"hello":
			return _page("steward", "Members and their guests, sir. Mr. Rourke's man, isn't it? You may sit in the lounge, but "
				+ "the gentlemen are talking. Hat on, voice down.", [{"id": "who", "text": "Who are the gentlemen?"},
				{"id": "pour", "text": "Pour me one."}])
		"who":
			return _page("steward", "Precinct captains, a judge who isn't here and a man from the water department who is. "
				+ "They come for the quiet.", [{"id": "pour", "text": "Pour me one."}])
		"pour":
			return _page("steward", "The club doesn't serve, sir, not since the Volstead Act. What the gentlemen bring in their "
				+ "own flasks is the gentlemen's own affair.", [{"id": "who", "text": "Who are the gentlemen?"}])
	return {}


## M012: Alderman Quilty of the Riverside Ward, in late at his desk.
func _quilty(step: String, _context: Dictionary) -> Dictionary:
	match step:
		"hello":
			return _page("quilty", "Mercer! Danny Mercer, back in the ward. Sit, sit. Office hours are ten till four, but the "
				+ "ward don't keep office hours. What can your alderman do for you?",
				[{"id": "respects", "text": "Just paying my respects."}, {"id": "late", "text": "What keeps you up?"}])
		"respects":
			return _page("quilty", "That's the spirit. Remember me in the spring, and tell Mr. Rourke his alderman asked "
				+ "after him.", [{"id": "late", "text": "What keeps you up?"}])
		"late":
			return _page("quilty", "Coal for the Widow Kerrigan, a job at the pumping station for the Nolan boy, and a letter "
				+ "to the Courier explaining why the holes in Kessler Street are a Republican plot.",
				[{"id": "respects", "text": "I'll let you get on."}])
	return {}


## M012: Leon Sobczak, North Branch Freight's night dispatcher - and his
## held freight, "Freight Doesn't Walk" (FreightJob; Danny's own job).
func _leon(step: String, context: Dictionary) -> Dictionary:
	var f := rackets.freight
	var truck := FreightJob._clock(f.deadline)
	match step:
		"hello":
			match f.stage:
				FreightJob.Stage.NOT_OFFERED:
					return _page("leon", "North Branch Freight, night dispatch.\" He looks you over. \"You've got the look of a fella "
						+ "who can carry a problem. Mine weighs twelve crates.", [{"id": "freight_hear", "text": "Go on."}])
				FreightJob.Stage.OFFERED:
					return _page("leon", "Well? Twelve crates, the %s truck, ten dollars." % truck,
						[{"id": "freight_accept", "text": "I'll see to it."}, {"id": "freight_decline", "text": "Find somebody else."}])
				FreightJob.Stage.ACCEPTED:
					var opts := []
					if f.learned.has("docked") and not f.leon_agreed:
						opts.append({"id": "freight_square", "text": "Your shed gang got docked six dollars for a dropped crate. Put it back."})
					else:
						opts.append({"id": "freight_beef", "text": "What's Walt's beef?"})
					var text := "Walt's still sitting on my freight. Truck's at %s." % truck
					if f.leon_agreed:
						text = "Petty cash is six dollars lighter in my head already. Go tell Walt before I change my mind."
					return _page("leon", text, opts)
				FreightJob.Stage.SETTLED:
					f.collect_fee(rackets)
					return _page("leon", "The truck's loading! Twelve crates, all present and correct.\" He counts ten dollars "
						+ "onto the blotter. \"Mine, not the company's. Worth every cent.", [], {"freight": "fee"})
				FreightJob.Stage.PAID:
					return _page("leon", "Hartmann's got their radios. If I ever need a problem carried, I know where you drink.")
				FreightJob.Stage.LAPSED:
					if f.how == "" and rackets.memory.recent("leon", "broken_promise", rackets.night, 14) > 0:
						return _page("leon", "I paid Walt's six myself at a quarter to the truck. It went out late. Next time "
							+ "just say no, Mercer - it's cheaper.")
					return _page("leon", "Paid the six out of my own pocket in the end. The company'll never know.")
				FreightJob.Stage.DECLINED:
					return _page("leon", "Suit yourself. I'll think of something before the truck.")
		"freight_hear":
			f.offer(rackets.night, float(context.get("minute", 20 * 60.0)))
			truck = FreightJob._clock(f.deadline)
			return _page("leon", "Radio cabinets for Hartmann's on State Street. Twelve crates, on the %s truck, or the "
				% truck + "company hangs it on me. They're sitting in my own shed under a tarp, and Walt Haney's gang won't "
				+ "lift a finger. Won't say why - not to the company man. Get that freight on the truck and there's ten "
				+ "dollars in it. Mine, not the company's.",
				[{"id": "freight_accept", "text": "I'll see to it."}, {"id": "freight_decline", "text": "Find somebody else."}],
				{"freight": "offered"})
		"freight_accept":
			if not f.accept():
				return _page("leon", "Too late for that, Mercer.")
			return _page("leon", "Good man. The shed's at the far end - the loading door on the yard. Walt Haney runs it. "
				+ "Don't tell him I sent you; it won't help.", [], {"freight": "accepted"})
		"freight_decline":
			f.decline()
			return _page("leon", "Suit yourself. I'll think of something before the truck.")
		"freight_beef":
			return _page("leon", "If I knew that, mister, I wouldn't need you. Ask around the yard - Dutch's counter hears "
				+ "everything that's said with a mouth full of pie.")
		"freight_square":
			if not f.talk_leon_round():
				return _page("leon", "We'll see.")
			return _page("leon", "Six dollars. For a crate Mickey Duffy dropped on his own foot.\" He rubs his eyes. "
				+ "\"...Fine. Petty cash. Better six dollars than twelve crates and my job. Tell Walt it's back.",
				[], {"freight": "leon_agrees"})
	return {}


## M012: Walt Haney, foreman of the freight shed, sitting on the Hartmann's freight.
func _walt(step: String, context: Dictionary) -> Dictionary:
	var f := rackets.freight
	match step:
		"hello":
			match f.stage:
				FreightJob.Stage.ACCEPTED:
					var hello := "If Sobczak sent you about them crates, tell him what I told him: nothing."
					if f.fight_lost_night == rackets.night:
						hello = "Back for seconds? Go home, Mercer. Put something on that eye."
					return _page("walt", hello, _walt_choices(context, not f.learned.has("docked")))
				FreightJob.Stage.SETTLED, FreightJob.Stage.PAID:
					return _page("walt", {"paid": "Mercer. Drinks are on the gang, any night you like.",
						"squared": "Six bucks back and nobody had to bleed for it. You ain't bad, for one of Rourke's.",
						"leaned": "Got what you came for. Now get out of my shed.",
						"beaten": "You got lucky. Don't count on it twice."}.get(f.how, "Freight's gone. Shed's closed."))
				FreightJob.Stage.LAPSED:
					return _page("walt", "Sobczak paid up himself in the end. Funny how money turns up when the truck's waiting.")
			return _page("walt", "Shed's closed to visitors, pal. Company rules - which this week we're keeping real careful.")
		"walt_why":
			return _page("walt", "Ask the company. They know everything, the company.\" He goes back to his stove. \"The whole "
				+ "yard knows, if you ask around. Ain't my job to tell you.", _walt_choices(context, false))
		"walt_six":
			f.learn("walt_said")
			return _page("walt", "Mickey Duffy dropped one crate of glassware. One. Company takes six bucks off the whole "
				+ "gang for it - off men making forty cents an hour. So no, we ain't in a hurry for the company.",
				_walt_choices(context, false))
		"walt_pay":
			if not f.settle(rackets, "paid"):
				return _page("walt", "Six dollars, Mercer. Not a nickel less.", _walt_choices(context, false))
			return _told("walt", "Walt looks at the money a long while, then at you. \"Boys! The Hartmann's crates. Shake a leg - "
				+ "Mercer's buying.\" The tarpaulin comes off and the shed gang get to work.", [], {"freight": "settled"})
		"walt_squared":
			if not f.settle(rackets, "squared"):
				return _page("walt", "Sobczak ain't said nothing to me.", _walt_choices(context, false))
			return _told("walt", "\"Sobczak said that? Out of petty cash?\" He spits in the stove. \"All right. Boys - the "
				+ "Hartmann's crates.\" The tarpaulin comes off.", [], {"freight": "settled"})
		"walt_threat":
			if f.threaten(rackets, context.get("gun_drawn", false)):
				return _told("walt", "Walt looks at the gun, then at his men. \"Boys. Load the Hartmann's crates. Mr. Mercer "
					+ "is in a hurry.\" Nobody looks at you while they work.", [], {"freight": "settled"})
			var opts := _walt_choices(context, false).filter(func(o: Dictionary) -> bool: return o.id != "walt_threat")
			return _page("walt", "With what, harsh language?\" The shed gang laughs. \"Go home, Mercer.", opts)
		"walt_fight":
			if not f.can_fight(rackets.night):
				return _page("walt", "Once a night's plenty.")
			return _page("walt", "The old way, huh?\" He takes off his cap and hangs it on a nail. \"Suits me.",
				[{"id": "bye", "text": "Raise your fists."}], {"fight": "walt"})
		"fight_won":
			return _told("walt", "Walt sits down hard on a crate and wipes his mouth. \"...Boys. Load the damn crates.\" "
				+ "They do it without a word.", [], {"freight": "settled"})
		"fight_lost":
			return _page("walt", "That's how it goes in the yards, pal. Freight stays where it is.\" He puts his cap back on. "
				+ "\"Come back when you've got something better than fists.")
	return {}


## Danny's ways with Walt: ask, know about the six, pay it, Leon's word, a threat, a fight.
func _walt_choices(context: Dictionary, ask_why: bool) -> Array:
	var f := rackets.freight
	var opts := []
	if ask_why:
		opts.append({"id": "walt_why", "text": "Why's the Hartmann's freight sitting here?"})
	if f.learned.has("docked") and not f.learned.has("walt_said"):
		opts.append({"id": "walt_six", "text": "This is about the six dollars the company docked your gang."})
	if f.learned.has("docked") or f.learned.has("walt_said"):
		if f.leon_agreed:
			opts.append({"id": "walt_squared", "text": "Sobczak's putting the six back out of petty cash. My word on it."})
		opts.append({"id": "walt_pay", "text": "Here's six dollars for the gang. Load the truck."})
	if f.threat_failed_night != rackets.night or context.get("gun_drawn", false):  # laughed off once; not with a gun out
		opts.append({"id": "walt_threat", "text": "Load those crates, Walt. Now."})
	if f.can_fight(rackets.night):
		opts.append({"id": "walt_fight", "text": "Then we settle it the old way."})
	return opts


## M012: the bell at the Mayor's gate: his house stays private, and his housekeeper says so.
func _mayor_gate(step: String) -> Dictionary:
	match step:
		"hello":
			return _told("mayor_gate", "You pull the bell. After a while a lamp comes down the garden path: a housekeeper in "
				+ "black, keys at her belt, who looks at your coat and your hat and makes up her mind. \"The Mayor is not "
				+ "receiving. If you've business with him, City Hall opens at nine.\"",
				[{"id": "rourke", "text": "Tell him Rourke's man called."}, {"id": "bye", "text": "Sorry to trouble you."}])
		"rourke":
			return _told("mayor_gate", "\"I'll tell him a man called.\" The lamp goes back up the path. A curtain moves in the "
				+ "parlour, and is still.", [{"id": "bye", "text": "Walk on."}])
	return {}


## M012 "After the Last Song": the Bird at the end of the bar after her last
## number, a glass of water dressed up as gin. Her question, and what Danny
## tells her - remembered (BirdScene's lines and the delivery notes are in
## docs/M012_PERFORMANCE_SCRIPT.md).
func _bird_scene(step: String) -> Dictionary:
	match step:
		"hello":
			return _told("bird", "\"Last week it was a fella from the Water Department. They all want the same thing from a "
				+ "singer - to hear they're not like the other fellas.\" She turns the glass and doesn't drink. \"You sit by "
				+ "the door and watch the room, not the stage. So tell me, Mercer: what do they say about me, when I'm not up "
				+ "there?\"", [{"id": "truth", "text": "That you're Rourke's canary, and you hear more than you sing."},
				{"id": "kind", "text": "Nothing worth repeating."},
				{"id": "guard", "text": "Ask me again when I know you better."}])
		"truth":
			return _told("bird", "\"Rourke's canary.\" She laughs once, without much in it. \"Honest. That's rarer in here than "
				+ "gin.\" She sets the glass down. \"Here's one back, then. I hear everything up there. I just never decided "
				+ "what it's worth - to keep it, or to stay.\"", [{"id": "bye", "text": "Goodnight, Bird."}], {"bird_scene": "truth"})
		"kind":
			return _told("bird", "\"Liar.\" But she smiles at the glass. \"A kind one. Kind comes dear in this town, Mercer - "
				+ "mind it doesn't cost you more than it costs them.\"", [{"id": "bye", "text": "Goodnight, Bird."}],
				{"bird_scene": "kind"})
		"guard":
			return _told("bird", "\"Fair.\" She looks at you a little longer than she needs to. \"Knowing a man and trusting "
				+ "him ain't the same animal. Most of them in here never learned the difference.\"",
				[{"id": "bye", "text": "Goodnight, Bird."}], {"bird_scene": "guard"})
	return {}


# ------------------------------------------------------------------ Rourke, at his corner table in the Copper Owl

## M007: a page for one of the job's lines (its words, and its performance tag shown beside the speaker).
func _job_page(id: String, options: Array = [], effects: Dictionary = {}) -> Dictionary:
	var line: Dictionary = JobLines.LINES[id]
	var page := _page(line.who, line.text, options, effects)
	if String(line.tone) != "":
		page["tone"] = line.tone
	return page


## M007: the job's option on Rourke's page (it takes the place of "How's business?"), or {}.
func _rourke_job_option() -> Dictionary:
	var job := rackets.job
	if not job.rourke_has_business(rackets.night):
		return {}
	match job.stage:
		RourkeJob.Stage.NOT_OFFERED, RourkeJob.Stage.OFFERED:
			return {"id": "job_offer", "text": JobLines.answer("job_offer")}
		RourkeJob.Stage.ACCEPTED, RourkeJob.Stage.RESOLVED:
			return {"id": "job_report", "text": JobLines.answer("job_report")}
	return {}


## M007: what Danny can say about the job (ids from RourkeJob.report_options).
func _job_report_options() -> Array:
	var job := rackets.job
	var truth := JobLines.answer("truth_" + job.outcome) if job.outcome != "" else ""
	if job.money_went == "lindqvist":
		truth += " " + JobLines.answer("truth_returned")
	var opts := []
	for id in job.report_options():
		var text := JobLines.answer(id)
		match id:
			"job_truth":
				text = truth
			"job_truth_hand":
				text = JobLines.answer(id) % [truth, Rackets.dollars(job.recovered)]
			"job_truth_keep":
				text = JobLines.answer(id) % truth
		opts.append({"id": id, "text": text})
	return opts


func _rourke(step: String, context: Dictionary) -> Dictionary:
	var r := rackets
	var b := r.boss
	var want := b.expected + b.rye_end()
	var D := Rackets.dollars
	var job := r.job
	match step:
		"job_offer":
			var said := job.offer(r, context.get("lefty_dead", false))
			if said == "moot":
				return _job_page("moot")
			return _job_page("offer", [
				{"id": "job_accept", "text": JobLines.answer("job_accept")},
				{"id": "job_postpone", "text": JobLines.answer("job_postpone")},
				{"id": "job_decline", "text": JobLines.answer("job_decline")},
			])
		"job_accept":
			return _job_page(job.accept(r), [], {"job": "accepted"})
		"job_postpone":
			return _job_page(job.postpone(r), [], {"job": "postponed"})
		"job_decline":
			return _job_page(job.decline(r), [], {"job": "declined"})
		"job_report":
			return _job_page("waiting", _job_report_options())
		"job_working", "job_handled", "job_truth", "job_truth_hand", "job_truth_keep":
			var out := job.report(step, r)
			var words := []
			for id in out.lines:
				words.append(JobLines.text(id))
			var page := _page("rourke", " ".join(words), [], {"job": "reported", "reward": out.reward})
			page["tone"] = JobLines.tone(out.lines[0])
			return page
	if step == "hello" and job.rourke_news != "":
		var news := job.take_rourke_news()
		var opts_n := []
		var jo := _rourke_job_option()
		if not jo.is_empty():
			opts_n.append(jo)
		return _job_page(news, opts_n)
	if step.begins_with("cafe"):
		return _rourke_cafe(step)
	match step:
		"hello":
			var job_opt := _rourke_job_option()
			var cafe_opt := _rourke_cafe_option()
			if b.settled and b.arrears == 0:
				var sq := [job_opt if not job_opt.is_empty() else {"id": "news", "text": "How's business, Mr. Rourke?"}]
				if not cafe_opt.is_empty():
					sq.append(cafe_opt)
				return _page("rourke", "We're square for tonight, Dimes. Go earn.", sq)
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
			opts.append(job_opt if not job_opt.is_empty() else {"id": "news", "text": "How's business, Mr. Rourke?"})
			if not cafe_opt.is_empty():
				opts.append(cafe_opt)
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
			# M009: what Danny gets up to on his own time, as far as talk has carried it
			for h in b.heard:
				if String(h.text).begins_with("Dimes "):
					bits.append("I hear %s. Your own time's your own business, Dimes - so long as it don't bring coppers to my door." \
						% String(h.text).trim_prefix("Dimes ").replace("Dimes", "you"))
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


## M010: Rourke's job at Rosie's Café, as an answer on his hello page ({} when there is nothing to say).
func _rourke_cafe_option() -> Dictionary:
	var c := rackets.cafe
	match c.stage:
		CafeJob.Stage.NOT_OFFERED, CafeJob.Stage.OFFERED:
			return {"id": "cafe", "text": "Anything else you need taken care of, Mr. Rourke?"}
		CafeJob.Stage.ACCEPTED, CafeJob.Stage.PLANTED:
			return {"id": "cafe_waiting", "text": "About Duggan's car..."}
		CafeJob.Stage.DONE:
			return {"id": "cafe_report", "text": "Duggan's Packard. It's done."}
	return {}


func _rourke_cafe(step: String) -> Dictionary:
	var r := rackets
	var c := r.cafe
	match step:
		"cafe":
			if not c.offerable():
				return _page("rourke", "You heard me the first time.")
			c.offer()
			return _page("rourke", "Sit. Vince Duggan's been selling beer in Halloran Square that comes off my trucks. Every night "
				+ "from ten he takes his coffee at Rosie's on Marlowe Avenue and leaves that green Packard of his at the kerb "
				+ "outside, like the street's his. I don't want him hurt. I want him to walk out of Rosie's and find a hole in "
				+ "the road where his car was. Eddie's got a parcel for you. You put it under the Packard, you walk away, you "
				+ "watch from somewhere it can't reach you. Nobody in that café gets a scratch, and nobody sees you do it. "
				+ "%s when it's done." % Rackets.dollars(CafeJob.REWARD), [
				{"id": "cafe_accept", "text": "Consider it done."},
				{"id": "cafe_later", "text": "Not tonight, Mr. Rourke."},
			])
		"cafe_accept":
			if not r.take_cafe_job():
				return _page("rourke", "We already shook on it.")
			return _page("rourke", "Good. Eddie's expecting you. And Dimes - quarter of an hour, Eddie says, once it's under. "
				+ "Don't be standing next to it.", [], {"cafe": "accepted"})
		"cafe_later":
			return _page("rourke", "Duggan's not going anywhere. Neither's the job. When you're ready.")
		"cafe_waiting":
			if c.stage == CafeJob.Stage.PLANTED:
				return _page("rourke", "Then what are you doing here? Go and watch.")
			return _page("rourke", "Well? Last I looked it was still a Packard. Eddie's got the parcel; Duggan's at Rosie's from ten.")
		"cafe_report":
			var pay := r.report_cafe()
			if pay <= 0:
				return _page("rourke", "You've been paid, Dimes.")
			var line := "I heard it from three directions before you got here. Nice and loud. Duggan'll think twice. Here's your %s." \
				% Rackets.dollars(pay)
			if c.seen:
				line += " And I hear a copper got a look at you. Keep your head down for a while."
			if c.caught_in_it:
				line += " Next time stand further off. You look like something the cat dragged in."
			return _page("rourke", line, [], {"cafe": "reported", "reward": pay})
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
	if int(out.get("job_reward", 0)) > 0:
		line += " And %s for the Lindqvist business, like I said." % D.call(out.job_reward)
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
