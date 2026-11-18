class_name Business
extends RefCounted
## One business of the Riverside Ward as plain numbers (pure, deterministic):
## the cash in its till, the stock of what it sells, how much of it its
## customers want, what a day costs it, and what its supplier can bring. It
## trades by itself through the night (the club) or the day (the shops) and
## restocks when it can afford to: a till run dry means a short delivery, a
## short delivery means empty shelves, and empty shelves mean thin takings.
## Money in cents; stock in units (bottles, crates, boxes of rounds).

var id := ""
var name := ""
## Who runs it (the person you talk to).
var keeper := ""
var cash := 0
var stock := 0
var capacity := 0
## What a customer pays for one unit (cents), and how many units its
## customers want in a full night (or day).
var price := 0
var demand := 0
## Takings that do not depend on stock (haircuts, the club's cover charge).
var fixed_takings := 0
## Rent, wages, the band: what a day costs (cents).
var expenses := 0
## Units its supplier brings each day at most, and their cost each.
var supply := 0
var supply_cost := 0
## When its customers come: "night" (sold through the evening) or "day"
## (sold while Danny sleeps).
var trade_hours := "day"
## Rourke's protection on it: the standard nightly rate (0 = not his).
var protection := 0
## Yesterday's results and a short history of profits (newest last).
var last_sales := 0
var last_takings := 0
var last_profit := 0
var history: Array = []
## Units its customers wanted that it could not sell, yesterday.
var last_shortfall := 0
## Units the supplier could not deliver last time because the till was short.
var missed_delivery := 0
## Fractional sales carried between clock ticks (night trade).
var _carry := 0.0


func _init(p_id: String = "", p_name: String = "") -> void:
	id = p_id
	name = p_name


## Sells to its customers for `share` of a full trading period (0..1):
## at most what is in stock. Returns the units sold.
func trade(share: float) -> int:
	_carry += demand * maxf(share, 0.0)
	var want := int(floor(_carry))
	_carry -= want
	var k := mini(want, stock)
	last_shortfall += want - k
	stock -= k
	cash += k * price
	last_sales += k
	last_takings += k * price
	return k


## The day after a night: the morning delivery, cash on delivery from what
## is left in the till (a till emptied in the night means a short delivery),
## then the day's trade (shops), the fixed takings and the costs (rent and
## wages are owed even when the till is empty). Returns a report.
func close_day() -> Dictionary:
	var wanted := mini(supply, maxi(0, capacity - stock))
	var affordable := wanted if supply_cost <= 0 else mini(wanted, maxi(0, cash) / supply_cost)
	missed_delivery = wanted - affordable
	stock += affordable
	cash -= affordable * supply_cost
	if trade_hours == "day":
		trade(1.0)
	cash += fixed_takings
	last_takings += fixed_takings
	cash -= expenses
	last_profit = last_takings - expenses - affordable * supply_cost
	history.append(last_profit)
	if history.size() > 5:
		history.pop_front()
	var report := {"id": id, "sales": last_sales, "shortfall": last_shortfall, "takings": last_takings,
		"profit": last_profit, "delivered": affordable, "missed": missed_delivery, "cash": cash, "stock": stock}
	last_sales = 0
	last_takings = 0
	last_shortfall = 0
	return report


## True when it is short of stock: an empty cellar or empty shelves.
func is_short() -> bool:
	return capacity > 0 and stock * 4 <= capacity


## How it has been doing lately: average profit of the recent days (cents).
func trend() -> int:
	if history.is_empty():
		return 0
	var total := 0
	for p in history:
		total += int(p)
	return total / history.size()


## What it can hand over for protection tonight. Asked, it keeps back what
## it needs for tomorrow's delivery; leaned on, it empties the till.
func protection_due(leaned: bool) -> int:
	if protection <= 0:
		return 0
	var want := protection * 3 / 2 if leaned else protection
	var keep := 0 if leaned else supply * supply_cost
	return clampi(cash - keep, 0, want)


func to_dict() -> Dictionary:
	return {"cash": cash, "stock": stock, "last_profit": last_profit, "history": history.duplicate(),
		"missed_delivery": missed_delivery, "carry": _carry, "last_sales": last_sales, "last_takings": last_takings,
		"last_shortfall": last_shortfall}


func from_dict(d: Dictionary) -> void:
	cash = int(d.get("cash", cash))
	stock = clampi(int(d.get("stock", stock)), 0, maxi(capacity, 0))
	last_profit = int(d.get("last_profit", 0))
	history = []
	for p in d.get("history", []):
		history.append(int(p))
	missed_delivery = int(d.get("missed_delivery", 0))
	_carry = float(d.get("carry", 0.0))
	last_sales = int(d.get("last_sales", 0))
	last_takings = int(d.get("last_takings", 0))
	last_shortfall = int(d.get("last_shortfall", 0))
