class_name QuarterLeads
extends RefCounted
## M015.13: three pieces of business that start in the new quarters (pure),
## found by listening, reading and asking - never handed out - and settled by
## Danny's own choices. Saved inside Quarters.
##
## Stall insurance (Canal Market, Danny's own): somebody signing himself "K."
## collects "stall insurance" from the market's stallholders before the
## market master gets his fees. The noticeboard and Josef Hrabal hint at it;
## Henry Chu names him - Kaz Wrobel, who eats at the Golden Lantern after
## eleven. Danny can beat him in a fistfight (he quits the market), buy him
## off ($5 of Danny's own, he finds another market), or cut himself in ($1 a
## night from Kaz while the stallholders go on paying - and Hrabal knows whose
## friend Danny is). Hrabal thanks him once for the first two.
##
## The State's Attorney's man (Lincoln Terrace -> Rourke): for a dollar the
## Belvedere's night manager mentions a man from the State's Attorney asking
## after "you people". Danny can tell Rourke (who is glad of the eyes) or keep
## it to himself; after two nights the man has checked out.
##
## A card for the Bird (the Paradise -> the Copper Owl): the Paradise's
## bandleader wants the Bird to sing for him and pays Danny a dollar to take
## her his card. Danny can give it to her, or hand it to Rourke instead (the
## Bird is Rourke's), or let it be (the bandleader stops asking after three
## nights). Each choice is remembered by the people it touches.

enum Stall { UNKNOWN, SUSPECTED, KNOWN, MET, SETTLED }
enum Sa { UNKNOWN, KNOWN, TOLD, LAPSED }
enum Card { NONE, CARRYING, TO_BIRD, TO_ROURKE, LAPSED }

## Kaz Wrobel eats at the Golden Lantern from eleven to two (the clock's minutes).
const KAZ_HOURS := [23.0 * 60.0, 26.0 * 60.0]
## What buying Kaz off costs Danny, and his cut a night if Danny is in on it (cents).
const KAZ_BUYOUT := 500
const KAZ_CUT := 100
## Hrabal's thanks from the stallholders' tin, once, by how it was settled.
const HRABAL_THANKS := {"beaten": 300, "bought": 200}
## The State's Attorney's man stays this many nights after Danny hears of him.
const SA_NIGHTS := 2
## The bandleader's dollar for carrying his card; he asks this many nights.
const CARD_FEE := 100
const CARD_NIGHTS := 3
## How much Rourke's trust grows for a useful word.
const TRUST_FOR_SA := 4
const TRUST_FOR_CARD := 3

var stall: int = Stall.UNKNOWN
## Where Danny heard of it: "board", "hrabal", "chu".
var stall_heard: Array[String] = []
## How it was settled: "beaten", "bought", "cut".
var stall_how := ""
var stall_thanked := false
var kaz_fights_lost := 0
## The last night Kaz handed over Danny's cut.
var kaz_paid_night := 0

var sa: int = Sa.UNKNOWN
var sa_night := 0

var card: int = Card.NONE
var card_night := 0


# ------------------------------------------------------------------ stall insurance

## Danny hears of the collector from `source`; true when he learnt something.
func hear_stall(source: String) -> bool:
	if stall >= Stall.SETTLED:
		return false
	var before: int = stall
	var fresh := not stall_heard.has(source)
	if fresh:
		stall_heard.append(source)
	stall = maxi(stall, Stall.KNOWN if source == "chu" else Stall.SUSPECTED)
	return stall != before or fresh


## Whether Kaz is at his table in the Golden Lantern at `minute` (not after
## he has quit the market).
func kaz_in(minute: float) -> bool:
	if stall == Stall.SETTLED and stall_how != "cut":
		return false
	return minute >= KAZ_HOURS[0] and minute < KAZ_HOURS[1]


## Danny has sat down with Kaz.
func meet_kaz() -> void:
	if stall < Stall.MET:
		stall = Stall.MET


## A fistfight with Kaz: won, he quits the market; lost, he laughs (Danny may
## try again another night).
func fought_kaz(won: bool) -> void:
	if stall == Stall.SETTLED:
		return
	if won:
		_settle("beaten")
	else:
		kaz_fights_lost += 1


## $5 of Danny's own and Kaz finds another market; false without the money.
func buy_off_kaz(r: Rackets) -> bool:
	if stall == Stall.SETTLED or r.money < KAZ_BUYOUT:
		return false
	r.money -= KAZ_BUYOUT
	_settle("bought")
	return true


## Danny in on it: a dollar a night from Kaz.
func cut_in() -> void:
	if stall != Stall.SETTLED:
		_settle("cut")


func _settle(how: String) -> void:
	stall = Stall.SETTLED
	stall_how = how


## Kaz hands over tonight's cut (once a night, only while Danny is in on it).
func collect_cut(r: Rackets) -> int:
	if stall_how != "cut" or kaz_paid_night == r.night:
		return 0
	kaz_paid_night = r.night
	r.money += KAZ_CUT
	return KAZ_CUT


## Hrabal's thanks for seeing Kaz off (once; never for a cut).
func thanks_due() -> int:
	if stall != Stall.SETTLED or stall_thanked:
		return 0
	return int(HRABAL_THANKS.get(stall_how, 0))


func take_thanks(r: Rackets) -> int:
	var k := thanks_due()
	if k <= 0:
		return 0
	stall_thanked = true
	r.money += k
	return k


# ------------------------------------------------------------------ the State's Attorney's man

func learn_sa(night: int) -> bool:
	if sa != Sa.UNKNOWN:
		return false
	sa = Sa.KNOWN
	sa_night = night
	return true


## Danny tells Rourke: Rourke is glad of the eyes (trust) and remembers it.
func tell_rourke_sa(r: Rackets) -> bool:
	if sa != Sa.KNOWN:
		return false
	sa = Sa.TOLD
	r.boss.trust = mini(100, r.boss.trust + TRUST_FOR_SA)
	r.memory.remember("rourke", "told_truth", r.night, "the State's Attorney's man at the Belvedere")
	return true


# ------------------------------------------------------------------ a card for the Bird

## The bandleader gives Danny his card and a dollar for carrying it (once ever).
func take_card(r: Rackets) -> bool:
	if card != Card.NONE:
		return false
	card = Card.CARRYING
	card_night = r.night
	r.money += CARD_FEE
	return true


## Danny gives the Bird the card: she remembers the favour.
func card_to_bird(r: Rackets) -> bool:
	if card != Card.CARRYING:
		return false
	card = Card.TO_BIRD
	r.memory.remember("bird", "favour", r.night, "the Paradise's card")
	return true


## Danny hands it to Rourke instead: Rourke is glad to know (trust), and has a
## word with the bandleader - who knows who told.
func card_to_rourke(r: Rackets) -> bool:
	if card != Card.CARRYING:
		return false
	card = Card.TO_ROURKE
	r.boss.trust = mini(100, r.boss.trust + TRUST_FOR_CARD)
	r.memory.remember("rourke", "told_truth", r.night, "the Paradise's bandleader after the Bird")
	return true


# ------------------------------------------------------------------ the nights

## A new evening: what has waited too long lapses.
func begin_night(night: int) -> void:
	if sa == Sa.KNOWN and night - sa_night >= SA_NIGHTS:
		sa = Sa.LAPSED
	if card == Card.CARRYING and night - card_night >= CARD_NIGHTS:
		card = Card.LAPSED


func to_dict() -> Dictionary:
	return {"stall": stall, "stall_heard": Array(stall_heard), "stall_how": stall_how, "stall_thanked": stall_thanked,
		"kaz_fights_lost": kaz_fights_lost, "kaz_paid_night": kaz_paid_night, "sa": sa, "sa_night": sa_night,
		"card": card, "card_night": card_night}


func from_dict(d: Dictionary) -> void:
	stall = clampi(int(d.get("stall", 0)), 0, Stall.SETTLED)
	stall_heard.clear()
	for s in d.get("stall_heard", []):
		if String(s) in ["board", "hrabal", "chu"] and not stall_heard.has(String(s)):
			stall_heard.append(String(s))
	stall_how = String(d.get("stall_how", ""))
	if not stall_how in ["", "beaten", "bought", "cut"] or (stall == Stall.SETTLED) != (stall_how != ""):
		stall_how = "" if stall != Stall.SETTLED else "beaten"
	stall_thanked = bool(d.get("stall_thanked", false))
	kaz_fights_lost = maxi(0, int(d.get("kaz_fights_lost", 0)))
	kaz_paid_night = maxi(0, int(d.get("kaz_paid_night", 0)))
	sa = clampi(int(d.get("sa", 0)), 0, Sa.LAPSED)
	sa_night = maxi(0, int(d.get("sa_night", 0)))
	card = clampi(int(d.get("card", 0)), 0, Card.LAPSED)
	card_night = maxi(0, int(d.get("card_night", 0)))
