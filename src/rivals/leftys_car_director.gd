class_name LeftysCarDirector
extends JobDirector
## M015: the game side of Lefty Moran's speedster (its state is LeftysCar, in
## Rackets). The car is an ordinary parked car of the ward - stealable, kept
## where it is left like any other (Fleet) - owned by "lefty". This watches
## what Lefty can see from where he stands: Danny taking it or driving it
## (he knows, and goes for his gun), his car standing somewhere else (he knows
## it is gone, not who took it), the car back at his kerb (he forgives, and
## remembers that too). A copper who saw the theft spreads the word: Lefty
## knows by the next evening. Each night he holds his grudge while he knows it
## was Danny and the car is not back.

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## Within this of its own parking place the car counts as back at his kerb.
const HOME_REACH := 140.0
## How often Lefty looks round (seconds).
const LOOK_EVERY := 0.25

var _look := 0.0
var _index := -1


func id() -> String:
	return "leftys_car"


func setup() -> void:
	game.fleet.car_taken.connect(_on_taken)


## The car's index in the fleet (-1 if the ward has none).
func index() -> int:
	if _index < 0:
		for i in game.fleet.specs.size():
			if String(game.fleet.specs[i].get("owner", "")) == "lefty":
				_index = i
				break
	return _index


func car() -> Car:
	var i := index()
	return game.fleet.cars[i] if i >= 0 else null


## Where it is parked by his corner.
func home() -> Vector2:
	var i := index()
	return game.fleet.specs[i].pos if i >= 0 else Vector2.INF


func at_home() -> bool:
	var c := car()
	return c != null and c.global_position.distance_to(home()) < HOME_REACH


func _lefty_ok() -> bool:
	return game.rival != null and not game.rival.is_down()


func _on_taken(i: int, witnessed: bool) -> void:
	if i != index():
		return
	if witnessed:
		game.rackets.lefty_car.word = true  # the copper's story reaches Lefty by the next evening
	if _lefty_ok() and game.rival.can_see(car().global_position):
		_he_saw("saw_taken")


## Every frame of the night: what Lefty can see from where he stands.
func clock(_minute: float, delta: float) -> void:
	_look -= delta
	if _look > 0.0:
		return
	_look = LOOK_EVERY
	var c := car()
	if c == null or c.has_meta("away"):
		return
	var m := game.rackets.lefty_car
	if game.player.car == c:
		if _lefty_ok() and not m.grudge() and game.rival.can_see(c.global_position):
			_he_saw("saw_driving")
		return
	if at_home():
		if m.knows == "danny" and not m.returned:
			m.bring_back()
			game.rackets.lefty_car_back()
			if _lefty_ok():
				game.rival.brain.grudge = false
			game.hud.show_notice("Lefty's speedster is back at his kerb.")
		elif m.knows == "gone":
			m.bring_back()
	elif m.knows == "" and _lefty_ok() and game.rival.can_see(c.global_position):
		m.learn_gone(game.rackets.night)  # his car, standing where he never left it


## He saw it with his own eyes: he knows, and goes for his gun.
func _he_saw(how: String) -> void:
	var r := game.rackets
	if not r.lefty_car.learn_danny(how, r.night):
		return
	r.lefty_car_taken(how)
	game.rival.provoke()
	game.rival.brain.grudge = true
	game.hud.show_notice("Lefty Moran saw you take his car!" if how == "saw_taken" else "Lefty Moran sees you in his car!")


## A new evening: the word from a copper reaches him; or his car is not where
## he left it. Then his grudge for the night.
func new_night() -> void:
	var m := game.rackets.lefty_car
	if car() != null and _lefty_ok():
		if m.word and not m.grudge():
			if m.learn_danny("word", game.rackets.night):
				game.rackets.lefty_car_taken("word")
		elif not at_home() and m.knows == "":
			m.learn_gone(game.rackets.night)
	m.word = false
	_apply_grudge()


func restored() -> void:
	_apply_grudge()


func _apply_grudge() -> void:
	if _lefty_ok() and game.rackets.lefty_car.grudge():
		game.rival.brain.grudge = true
