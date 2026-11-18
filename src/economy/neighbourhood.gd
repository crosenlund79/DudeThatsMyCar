class_name Neighbourhood
extends RefCounted
## The businesses of the Riverside Ward and their days (pure, deterministic).
## The Copper Owl sells drinks through the night as the clock runs; the shops
## trade by day while Danny sleeps; each morning the suppliers come and are
## paid from the till if it can. Nothing here is random: the same nights give
## the same ward. All numbers are provisional (cents, units).
##
##   Copper Owl  the club: no supplier of its own since Augie's man got pinched,
##               so its cellar fills only with the rye Danny brings.
##   Sal         barber; his Cicero man brings 6 bottles of rye a day.
##   Novak       grocer; the truck brings 10 crates each morning, cash on delivery.
##   Eddie       back room at Lindqvist's; a box of .45 rounds comes in each day.

## Minutes from the start of a night to dawn (the night trade is spread over them).
var night_minutes := 600.0
var businesses := {}
## How much of tonight's trade has happened (0..1).
var night_done := 0.0


static func riverside() -> Neighbourhood:
	var n := Neighbourhood.new()
	n._add("copper_owl", "The Copper Owl", "augie", {"cash": 4000, "stock": 6, "capacity": 14, "price": 600, "demand": 8,
		"fixed_takings": 800, "expenses": 1600, "supply": 0, "supply_cost": 0, "trade_hours": "night", "protection": 1000})
	n._add("barber_shop", "Sal's Barber Shop", "sal", {"cash": 2000, "stock": 6, "capacity": 10, "price": 200, "demand": 2,
		"fixed_takings": 1200, "expenses": 800, "supply": 6, "supply_cost": 90, "trade_hours": "day", "protection": 0})
	n._add("grocery", "Novak's Grocery", "novak", {"cash": 2100, "stock": 2, "capacity": 12, "price": 250, "demand": 10,
		"fixed_takings": 0, "expenses": 400, "supply": 10, "supply_cost": 150, "trade_hours": "day", "protection": 500})
	n._add("eddie", "Eddie's crate", "eddie", {"cash": 1000, "stock": 4, "capacity": 6, "price": 0, "demand": 0,
		"fixed_takings": 0, "expenses": 0, "supply": 1, "supply_cost": 120, "trade_hours": "day", "protection": 0})
	return n


func _add(id: String, title: String, keeper: String, v: Dictionary) -> void:
	var b := Business.new(id, title)
	b.keeper = keeper
	for k in v:
		b.set(k, v[k])
	businesses[id] = b


func get_business(id: String) -> Business:
	return businesses.get(id)


func club() -> Business:
	return businesses["copper_owl"]


## Total cash in every till (for checking that deals only move money).
func total_cash() -> int:
	var t := 0
	for b in businesses.values():
		t += (b as Business).cash
	return t


## The night goes on: `minutes` of it pass (the club serves its customers).
func advance(minutes: float) -> void:
	var share := clampf(minutes / night_minutes, 0.0, 1.0 - night_done)
	if share <= 0.0:
		return
	night_done += share
	for b in businesses.values():
		if (b as Business).trade_hours == "night":
			(b as Business).trade(share)


## Dawn and the day after: the rest of the night's trade, then each
## business's day (shops trade, costs, deliveries). Returns the reports.
func close_night() -> Array:
	advance((1.0 - night_done) * night_minutes)
	var reports := []
	for b in businesses.values():
		reports.append((b as Business).close_day())
	night_done = 0.0
	return reports


func to_dict() -> Dictionary:
	var out := {"night_done": night_done}
	for id in businesses:
		out[id] = (businesses[id] as Business).to_dict()
	return out


func from_dict(d: Dictionary) -> void:
	night_done = clampf(float(d.get("night_done", 0.0)), 0.0, 1.0)
	for id in businesses:
		if d.has(id):
			(businesses[id] as Business).from_dict(d[id])
