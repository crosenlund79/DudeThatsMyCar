class_name Fights
extends RefCounted
## M014 (from main): fistfights (M007) in the game - the dial over the street,
## Danny and his man standing still, the punches' recoil and sounds, the
## bruises dealt out when it is over, and whoever asked for the fight told how
## it went. A fight agreed in a talk starts when the talk ends (`request`).
## The rules are the pure FistFight / FightInjuries; reusable for any opponent.

var game: Game
var fighting := false
var opponent: Walker
var _done: Callable
## A fight agreed in a talk, started when the talk ends: a Callable that
## starts it (or an invalid one). M007: Lefty; M012: Walt.
var _pending := {}


func _init(p_game: Game) -> void:
	game = p_game


## A fight with `who` once the talk ends; `start_it` is called then (deferred).
func request(who: String, start_it: Callable) -> void:
	_pending = {"who": who, "start": start_it}


func pending() -> String:
	return String(_pending.get("who", ""))


## The talk ended: a fight agreed in it starts (on the next idle moment).
func talk_ended(_who: String) -> void:
	if _pending.is_empty():
		return
	var start_it: Callable = _pending.start
	if start_it.is_valid():
		start_it.call_deferred()


## Clears the pending fight (the job's own start function does, as it starts).
func clear_pending() -> void:
	_pending = {}


## M007: a fistfight with `p_opponent` (a Walker) - the dial over the street,
## five checks; `done` is called with (won, results) once it is over, after the
## bruises are dealt out. False (and nothing happens) when a fight is already
## on, Danny is not on foot or either man is down. Reusable for any opponent.
func start(p_opponent: Walker, opponent_name: String, done: Callable, zone_bonus: float = 0.0,
		speed_scale: float = 1.0) -> bool:
	var walker := game.walker
	var player := game.player
	if fighting or not player.on_foot() or walker.down or p_opponent == null or p_opponent.down:
		return false
	game.dialogue.end()
	fighting = true
	opponent = p_opponent
	_done = done
	player.set_physics_process(false)
	walker.move = Vector2.ZERO
	walker.velocity = Vector2.ZERO
	if walker.gun != null:
		walker.gun.holster()
	walker.aim_point = p_opponent.global_position
	p_opponent.aim_point = walker.global_position
	p_opponent.move = Vector2.ZERO
	var rival := game.rival
	if rival != null and p_opponent == rival.body:
		rival.held = true
	var seed_value := game.rackets.night * 1000 + int(walker.global_position.x) % 997
	var f := FistFight.new(game.fight_rules, seed_value, zone_bonus - walker.condition.aim_spread() * 2.0, speed_scale)
	var dial := game.hud.fight_dial
	dial.start(f, opponent_name)
	if not dial.check_done.is_connected(_on_check):
		dial.check_done.connect(_on_check)
		dial.finished.connect(_on_over)
	return true


## Space during a fight: the dial.
func press() -> void:
	game.hud.fight_dial.press()


func _on_check(hit: bool, _index: int) -> void:
	game.soundscape.play("fight/punch_landed" if hit else "fight/punch_taken", -2.0)
	var walker := game.walker
	var who: Walker = opponent if hit else walker
	var other: Walker = walker if hit else opponent
	if who != null and other != null:
		var away := (who.global_position - other.global_position).normalized()
		who.sprite.position = away * 4.0
		var t := game.root.create_tween()  # (bound to the scene, as before)
		t.tween_property(who.sprite, "position", Vector2.ZERO, 0.18)


func _on_over(won: bool, results: Array) -> void:
	fighting = false
	if game.rival != null:
		game.rival.held = false
	game.player.set_physics_process(true)
	FightInjuries.apply_to_danny(game.walker.condition, results, won)
	if opponent != null:
		FightInjuries.apply_to_opponent(opponent.condition, results, won)
	game.hud.show_notice("You won the fight." if won else "You lost the fight. C shows the damage.")
	var done := _done
	_done = Callable()
	if done.is_valid():
		done.call(won, results)
	game.save()
