class_name RourkeJobDirector
extends JobDirector
## M014 (from main): the game side of Rourke's Lindqvist job (M007) - Lefty
## Moran on his corner outside Doyle's Garage: talking to him, the fistfight a
## talk can come to (Eddie's tip widens the zone, a wounded Lefty is slower),
## Danny's rounds in him, the next step on the HUD and on the city map. The
## job's course, money and lies are the pure RourkeJob (in Rackets).

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


const FIGHT_TIP_BONUS := 14.0
const FIGHT_HURT_PACE := 0.85


func id() -> String:
	return "rourke"


## Where Lefty stands: his corner outside Doyle's Garage, and the other end of his beat.
func post() -> Array[Vector2]:
	var at := game.locations
	return [at.at("riverside/place/lefty_post"), at.at("riverside/place/lefty_post_east")] as Array[Vector2]


func effects() -> Dictionary:
	return {"job": func(_v: Variant, _e: Dictionary) -> void: _job_step()}


func fights() -> Dictionary:
	return {"lefty": _fight_lefty}


## M007: Danny's gun settles Rourke's job too (the M006 rules handle the shooting).
func setup() -> void:
	var rival := game.rival
	rival.body.hurt.connect(func(_region: String, _level: int) -> void:
		if rival.body.last_shooter == game.walker:
			_lefty_shot(false))
	rival.struck_down.connect(func() -> void:
		if rival.body.last_shooter == game.walker:
			_lefty_shot(true))


func _job_step() -> void:
	var step := game.rackets.job.objective()
	if not step.is_empty():
		game.hud.show_notice(step.text)


## Lefty in the street, on his feet and not after Danny: E talks to him.
func spot(at: Vector2) -> Dictionary:
	var rival := game.rival
	if rival != null and not rival.is_down() and not rival.is_hostile() \
			and at.distance_to(rival.body.global_position) < 40.0:
		return {"id": "lefty", "prompt": "Talk to Lefty Moran"}
	return {}


func use(_spot: Dictionary) -> void:
	game.rival.body.aim_point = game.walker.global_position
	game.dialogue.open("lefty")


## M007: Lefty put up his fists ("Raise your fists" or walking away from the
## line starts it). Knowing how he fights (Eddie's tip) widens the zone; a
## wounded Lefty is slower.
func _fight_lefty() -> void:
	game.fights.clear_pending()
	var rival := game.rival
	if rival == null or rival.is_down() or game.walker.global_position.distance_to(rival.body.global_position) > 90.0:
		return
	var bonus := FIGHT_TIP_BONUS if game.rackets.job.learned.has("tip") else 0.0
	var pace := FIGHT_HURT_PACE if rival.body.condition.worst() >= BodyCondition.Level.WOUNDED else 1.0
	game.fights.start(rival.body, Rival.NAME, _on_lefty_fight, bonus, pace)


func _on_lefty_fight(won: bool, _results: Array) -> void:
	var r := game.rackets
	game.dialogue.talking = "lefty"
	game.rival.body.aim_point = game.walker.global_position
	game.dialogue.show(game.talk.choose("lefty", "job_fight_won" if won else "job_fight_lost", game.dialogue.context()))
	if won:
		game.soundscape.play_deal("lefty", r.job.recovered, 0)
	game.hud.set_purse(r.money, r.bottles, r.held)
	game.hud.show_notice(r.job.objective().get("text", ""))


## M007: Danny shot Lefty (`dead`: and killed him).
func _lefty_shot(dead: bool) -> void:
	var r := game.rackets
	var was := r.job.outcome
	r.job.shot_lefty(r, dead)
	if was == "" and r.job.outcome == "killed":
		game.hud.show_notice("Lefty Moran won't be collecting at Lindqvist's again. " + r.job.objective().get("text", ""))
	game.save()


## M007: Rourke's job on the map - what next, and the place it concerns.
func on_map() -> void:
	var hud := game.hud
	var step := game.rackets.job.objective()
	var at := Vector2.INF
	var lefty_at := Vector2.INF
	if game.rackets.job.knows_culprit() and not game.rival.is_down():
		lefty_at = post()[0]
	match String(step.get("where", "")):
		"lefty":
			at = lefty_at
		"copper_owl", "hardware":
			for pl in hud.minimap.places:
				if pl.id == step.where:
					at = pl.pos
	hud.city_map.set_job(String(step.get("text", "")), at, lefty_at)
