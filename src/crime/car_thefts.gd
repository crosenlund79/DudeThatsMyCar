class_name CarThefts
extends RefCounted
## Whose car is whose, and which ones Danny has taken tonight (pure). Danny
## owns one car; any other he drives off in is stolen - once: getting back
## into a car he has already taken is not a new theft. The cars are back with
## their owners by the next evening, so the record is kept for one night.
## A theft only matters to the police if an officer could see it happen
## (in sight range, no building between): PoliceOfficer.witness_theft.

const DANNY := "danny"
## How far an officer can make out someone breaking into a car (px).
const WITNESS_RANGE := 380.0

## car index -> owner (from the layout).
var owners := {}
## car index -> true: taken tonight.
var taken := {}


func _init(layout_cars: Array = []) -> void:
	for i in layout_cars.size():
		owners[i] = String(layout_cars[i].get("owner", ""))


## M008: a parked car of a neighbouring district joins the list when the
## district is first built. Returns its index.
func add(owner_name: String) -> int:
	var i := owners.size()
	owners[i] = owner_name
	return i


func is_dannys(index: int) -> bool:
	return owners.get(index, "") == DANNY


func owner(index: int) -> String:
	return owners.get(index, "")


## Danny gets into car `index`. Returns true when that is a new theft.
func get_in(index: int) -> bool:
	if index < 0 or is_dannys(index) or taken.has(index):
		return false
	taken[index] = true
	return true


func is_stolen(index: int) -> bool:
	return taken.has(index)


## A new night: the cars are back where their owners left them.
func clear() -> void:
	taken.clear()


## Whether an officer at `officer` could see a car being broken into at `car`
## (`clear_view`: no building between them).
static func witnessed(officer: Vector2, car: Vector2, clear_view: bool) -> bool:
	return clear_view and officer.distance_to(car) <= WITNESS_RANGE
