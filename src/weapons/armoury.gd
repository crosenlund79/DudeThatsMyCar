class_name Armoury
extends RefCounted
## M014 (from main): Danny's guns in the game - his own .45 (M002), Eddie's
## Thompson while it is on loan (M010: under his coat with its own rounds, Tab
## to take it in hand, back to Eddie when the loan ends), the rounds Eddie
## sells, the notices when a gun clicks dry or changes hands, the Thompson's
## climb on the view, and the guns' part of the save. The guns themselves are
## Gun (pure) carried by the PlayerController.

var game: Game
## Danny's own .45 (whichever gun is in his hand: `game.walker.gun`).
var pistol: Gun = null
## Eddie's Thompson while Danny has it (null otherwise).
var thompson: Gun = null


func _init(p_game: Game) -> void:
	game = p_game


## M015: the gun people can see in Danny's hand: 0 none (put away, or he is in
## a car, or down), 1 a handgun, 2 Eddie's Thompson (GunSight).
func shown_level() -> int:
	var player := game.player
	var walker := game.walker
	if player == null or walker == null or not player.on_foot() or walker.down:
		return GunSight.NONE
	var g := walker.gun
	if g == null or not g.is_drawn():
		return GunSight.NONE
	return GunSight.THOMPSON if g == thompson else GunSight.HANDGUN


## M015: {pos, level} for the street life (StreetLife.gun_shown).
func shown() -> Dictionary:
	return {"pos": game.walker.global_position, "level": shown_level()}


## The saved rounds back in the gun he holds (after the walker exists).
func load_gun(saved: Dictionary) -> void:
	var walker := game.walker
	if not saved.is_empty() and walker.gun != null:
		walker.gun.ammo = clampi(int(saved.get("ammo", walker.gun.ammo)), 0, game.gun_rules.magazine)
		if walker.gun.spare >= 0:
			walker.gun.spare = maxi(0, int(saved.get("spare", walker.gun.spare)))


## The .45 in his hand, the Thompson under his coat if it is on loan (M010).
func arm() -> void:
	var player := game.player
	pistol = game.walker.gun
	player.carry(pistol, game.resolver.get_texture(game.gun_rules.look))
	if game.rackets.loan.out:
		arm_thompson(true)  # M010: still on loan from Eddie


## Every round: the flash and the sound (and the Thompson's climb); a dry click,
## a gun changing hands: a word on the screen.
func wire() -> void:
	var player := game.player
	var gunfire := game.gunfire
	var walker := game.walker
	player.fired.connect(func(muzzle: Vector2, dir: Vector2) -> void:
		gunfire.on_fired(muzzle, dir, walker.gun.rules.sound)
		if walker.gun.rules.automatic:
			game.shake.kick -= dir * 2.2)  # M010: the Thompson climbs and shakes the view a little
	player.gun_event.connect(gunfire.on_gun_event)
	player.gun_event.connect(func(e: String, _at: Vector2) -> void:
		if e == "empty" and walker.gun == thompson:
			game.hud.show_notice("Click. The Thompson's dry. Eddie loads her again when she's back home.")
		elif e == "empty":
			game.hud.show_notice("Click. Out of rounds. Eddie sells them, in the back of Lindqvist Hardware.")
		elif e == "switched":
			game.hud.show_notice("The Thompson in your hands." if walker.gun == thompson else "Your .45 in your hand."))


## What Eddie's pages do to the guns: rounds bought, the Thompson lent or back.
func wire_dialogue() -> void:
	var dialogue := game.dialogue
	dialogue.on_context(func() -> Dictionary: return {"gun_out": shown_level()})  # M015: who won't deal with it out
	dialogue.on_effect("holster", func(_v: Variant, _e: Dictionary) -> void:  # M015: put away, as they asked
		if game.walker.gun != null:
			game.walker.gun.holster())
	dialogue.on_effect("rounds", func(v: Variant, _e: Dictionary) -> void:
		if pistol != null:
			pistol.add_spare(int(v)))
	dialogue.on_effect("thompson", func(v: Variant, _e: Dictionary) -> void: _thompson_effect(String(v)))  # M010


func _thompson_effect(what: String) -> void:
	match what:
		"lent":
			arm_thompson(true)
			game.hud.show_notice("Eddie's Thompson is under your coat. Tab takes it in hand.")
		"returned":
			arm_thompson(false)


## M010: Eddie's Thompson goes under Danny's coat (on loan, with its own
## rounds) or back to Eddie (the .45 in hand again).
func arm_thompson(on: bool) -> void:
	var rules := game.thompson_rules
	var look := game.resolver.get_texture(rules.look)
	var r := game.rackets
	if on and thompson == null:
		thompson = Gun.new(rules)
		thompson.ammo = clampi(r.loan.ammo, 0, rules.magazine)
		thompson.spare = maxi(0, r.loan.spare)
		game.player.carry(thompson, look)
	elif not on and thompson != null:
		game.player.carry(thompson, look, false)
		thompson = null


## Into the save: the .45's rounds; the Thompson's go with the loan (M010).
func save_into(data: Dictionary) -> void:
	if pistol != null:
		data["gun"] = {"ammo": pistol.ammo, "spare": pistol.spare}
	if thompson != null:  # M010: the Thompson's rounds go with the loan
		data.rackets.loan.ammo = thompson.ammo
		data.rackets.loan.spare = thompson.spare
