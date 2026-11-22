class_name FreightJobDirector
extends JobDirector
## M014 (from main): the game side of "Freight Doesn't Walk" (M012) - the held
## crates in North Branch Freight's shed (there while they are held, gone once
## they went out), the step on the HUD, the fistfight with Walt Haney, the fee
## in the purse, the truck that comes whether or not Danny has settled it. The
## job's course and money are the pure FreightJob (in Rackets).


func id() -> String:
	return "freight"


func effects() -> Dictionary:
	return {"freight": func(v: Variant, _e: Dictionary) -> void: effect(String(v))}


func fights() -> Dictionary:
	return {"walt": _fight_walt}


## The shed as the job left it, whenever its room is built.
func rooms_built() -> void:
	sync()


## The truck came; Leon sorted it himself.
func clock(minute: float, _delta: float) -> void:
	var r := game.rackets
	if r.freight.advance(r, minute) == "lapsed":
		sync()
		game.save()


## What a step of the job changes in the game: the crates in the shed, a word
## on the notebook, the purse.
func effect(what: String) -> void:
	var f := game.rackets.freight
	match what:
		"accepted", "learned", "leon_agrees":
			game.hud.show_notice(f.objective())
		"settled":
			if f.crates_out:
				game.soundscape.play("places/door", -6.0)
				game.hud.show_notice("The Hartmann's crates are going out on the truck. Leon owes you ten dollars.")
		"fee":
			game.show_purse()
	sync()


## The held crates in the shed while they are held; gone once they went.
func sync() -> void:
	game.interiors.set_furniture_present("freight_shed", "interiors/freight_crates", not game.rackets.freight.crates_out)


## The fistfight with Walt Haney in the freight shed (the M007 dial).
func _fight_walt() -> void:
	game.fights.clear_pending()
	var walt := game.interiors.person("freight_shed", "walt")
	if walt == null or walt.down or game.walker.global_position.distance_to(walt.global_position) > 120.0:
		return
	game.fights.start(walt, "Walt Haney", _on_walt_fight)


func _on_walt_fight(won: bool, _results: Array) -> void:
	var r := game.rackets
	r.freight.fought(r, won)
	game.dialogue.start("walt")
	game.dialogue.show(game.talk.choose("walt", "fight_won" if won else "fight_lost", game.dialogue.context()))
	effect("settled" if won else "")
	game.save()
