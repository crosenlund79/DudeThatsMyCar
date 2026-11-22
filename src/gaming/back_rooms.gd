class_name BackRooms
extends Node2D
## M014 (from main): the Copper Owl's back rooms in play - the card table
## (M010), Leo's wheel (M011, M013), the three machines (M011, M013) and the
## gaming room's evening (M013.6). Owns their state, moves Danny's money for
## them (once a deal, a round, a pull), and answers their screens. The rules
## live in the pure models (PokerNight, Roulette, RouletteTable, SlotMachine,
## GamingRoom); this is the game side: who sits where, the sounds, the lines
## over heads, the save.

var game: Game

## M010: the back-room card game, night by night.
var poker := PokerNight.new()
## M011: Danny's chips at the wheel; M013: Leo's wheel, round after round.
var roulette: Roulette
var wheel: RouletteTable
var _drop_heard := false
## M013.3: the regulars playing at Leo's wheel, and the words over heads in the room.
var wheel_patrons: RoulettePatrons
var room_lines: RoomLines
var react_rng := RandomNumberGenerator.new()
## M013.6: the gaming room's evening (who is in, where) and its life while Danny is in it.
var gaming_room := GamingRoom.new()
var room_life: GamingRoomLife
var _in_gaming_room := false
var _unseat_later: Array = []
## What Danny had in his pocket when he stepped up to the wheel (to tell him how he did).
var _wheel_start := 0
## M011: the gaming room's three machines (one SlotMachine each, its own rules),
## the one Danny is at (-1: none) and what he had when he stepped up.
var slot_machines: Array[SlotMachine] = []
var slot_at := -1
var _slot_start := 0
var slot_rng := RandomNumberGenerator.new()
## M013: the card players' taunts - only where a recording of the line exists
## (custom/audio/voice/poker/<id>; none ship), now and then, never over
## another voice. `last_taunt` keeps the line picked (for tests and the
## recording draft), recorded or not.
var last_taunt := {}
var taunt_rng := RandomNumberGenerator.new()


func _init(p_game: Game = null) -> void:
	game = p_game


## The card game's state from the save, and tonight's players (early: before
## the rooms are built, as M010 had it).
func load_poker(saved: Dictionary, night: int) -> void:
	poker.from_dict(saved)
	poker.begin_night(night)


## The tables and the room, wired to their screens (once the HUD exists; the
## node is in the tree). `saved_slots`: the machines as the save has them.
func setup(saved_slots: Array) -> void:
	var hud := game.hud
	hud.poker_view.bought_in.connect(_on_bought_in)
	hud.poker_view.leave_requested.connect(leave_poker)
	hud.poker_view.level_requested.connect(func(i: int) -> void:  # M013: the stakes, before he sits down
		if poker.set_level(i):
			hud.poker_view.refresh_buy_in(game.rackets.money))
	hud.poker_view.hand_over.connect(game.save)  # M013: every hand's result kept (a save never undoes a loss)
	hud.poker_view.beat_shown.connect(poker_taunt)  # M013: the hook for recorded taunts
	hud.poker_view.sound.connect(func(kind: String) -> void: game.soundscape.play("poker/" + kind, -4.0))
	roulette = Roulette.new(game.roulette_rules)
	wheel = RouletteTable.new(game.roulette_rules, roulette)  # M013: an unpredictable draw in play (tests seed their own)
	wheel_patrons = RoulettePatrons.new(game.roulette_rules)  # M013.3: their own generator, never the draw's
	wheel.set_patrons(wheel_patrons)  # (who is at the rail: the room's life, M013.6)
	react_rng.randomize()
	taunt_rng.randomize()
	room_lines = RoomLines.new()
	add_child(room_lines)
	room_lines.setup(load(Hud.FONT_PATH))
	gaming_room.begin_night(game.rackets.night)
	room_life = GamingRoomLife.new()
	add_child(room_life)
	room_life.setup(game.interiors.view_of("gaming_room"), gaming_room, room_lines, game.soundscape)
	room_life.at_wheel.connect(_on_patron_at_wheel)
	var rv := hud.roulette_view
	rv.bet_requested.connect(bet)
	rv.take_back_requested.connect(take_back)
	rv.clear_requested.connect(clear_bets)
	rv.repeat_requested.connect(repeat_bets)
	rv.leave_requested.connect(leave_roulette)
	for r in game.slot_rules:
		slot_machines.append(SlotMachine.new(r))
	slot_rng.randomize()
	hud.slot_view.pull_requested.connect(pull)
	hud.slot_view.reels_stopped.connect(_on_slot_stopped)
	hud.slot_view.leave_requested.connect(leave_slot)
	hud.slot_view.sound.connect(_on_slot_sound)
	hud.slot_view.hold_requested.connect(hold)  # M013
	hud.slot_view.stake_requested.connect(set_stake)
	for i in mini(saved_slots.size(), slot_machines.size()):
		slot_machines[i].from_dict(saved_slots[i])  # the reels, lamps, holds and stake as they were


## M014: the back rooms' furniture is written in the ward's own coordinates
## (RiversideInteriors); in the world it is wherever the ward is placed.
func _ward(local: Vector2) -> Vector2:
	return game.layout.to_world(local)


## At one of the tables (the card table, the wheel or a machine): their keys only.
func at_a_table() -> bool:
	return game.hud.poker_view.is_open() or at_a_game()


## M011: at the wheel or at one of the machines.
func at_a_game() -> bool:
	return game.hud.roulette_view.is_open() or game.hud.slot_view.is_open()


## The keys while a table's screen is up (true: the table took them).
func handle_key(event: InputEvent) -> bool:
	var hud := game.hud
	if hud.poker_view.is_open():
		hud.poker_view.handle_key(event)  # M010: at the card table only the table's keys
		return true
	if hud.roulette_view.is_open():
		hud.roulette_view.handle_key(event)  # M011: at the wheel only the wheel's keys
		return true
	if hud.slot_view.is_open():
		hud.slot_view.handle_key(event)  # M011: at a machine only its keys
		return true
	return false


## Every frame before the clock (M013): Leo's wheel and the regulars about the
## gaming room - not while the menu is up; the card players kept in their chairs.
func update(delta: float, menu_open: bool) -> void:
	if game.hud.poker_view.is_open():
		sync_card_players()  # M010: busted players go home, the late man pulls up a chair
	if not menu_open:
		_wheel_update(delta)  # M013: Leo's wheel, round after round
		_room_life_update(delta)  # M013.6: the regulars about the gaming room


## The hour to go home: the card game breaks up (M010), the round under way is
## the wheel's last (M013).
func closing_time() -> void:
	poker.closing = true
	wheel.closing = true


## A new night: the card players back with fresh money, the cover off the
## wheel, tonight's regulars. Returns what the wheel still owed Danny (cents).
func begin_night(night: int) -> int:
	poker.begin_night(night)  # M010: the card players are back with fresh money
	sync_card_players()
	var owed := wheel.begin_night()  # M013: the cover off the wheel
	gaming_room.begin_night(night)  # M013.6: tonight's regulars
	return owed


## Into the save: the card game, the machines, and what Danny has on the
## tables counted as his money (a hand under way void, a spin or a pull under
## way settled).
func save_into(data: Dictionary) -> void:
	data["poker"] = poker.to_dict()
	if poker.seated():
		data.rackets.money += poker.stake_for_save()  # M010: his chips count as his money; a hand under way is void
	if roulette != null:
		data.rackets.money += roulette.for_save()  # M011: chips on the layout are his; a spin under way counts as settled
	for m in slot_machines:
		data.rackets.money += m.for_save()  # M011: a pull under way is decided: its win counts
	data["slots"] = slot_machines.map(func(m: SlotMachine) -> Dictionary: return m.to_dict())  # M013: reels, lamps, holds, stake


## M006: Danny hit - nobody stays at the wheel or a machine.
func danny_hurt() -> void:
	leave_roulette()  # M011: nor at the wheel
	leave_slot()  # nor at a machine


## M006: someone in the back rooms struck down (`named`: one of the ward's own):
## no more chips or cards from him; no croupier, no wheel.
func person_down(room: String, id: String, named: bool) -> void:
	if room == "gaming_room" and Patrons.ROSTER.has(id) and wheel_patrons != null:
		wheel_patrons.unseat(id)  # M013.3: no more chips from a regular struck down
	if not named:
		return
	if room == "back_room":
		poker.gone[id] = "hurt"  # M010: carried off: no more cards for him tonight
		if poker.seated():
			leave_poker()
	if room == "gaming_room" and id == "croupier":
		leave_roulette()  # M011: no croupier, no wheel


# ------------------------------------------------------------------ the card table (M010, M013)

## M010: E at the empty chair in the Copper Owl's back room: Danny sits down
## and the buy-in comes up (or why he cannot play tonight).
func open_poker() -> void:
	var interiors := game.interiors
	if game.hud.poker_view.is_open() or interiors.current == null or interiors.current.id != "back_room":
		return
	var chair: Vector2 = _ward(RiversideInteriors.TABLE) + Vector2(0, 44)
	game.player.sit({"pos": chair, "facing": -PI / 2, "stand": chair + Vector2(0, 16), "kind": "chair"})
	game.hud.poker_view.layout_for(get_viewport().get_visible_rect().size)
	game.hud.poker_view.open(poker, game.rackets.money)
	game.mouse(true)


func _on_bought_in(amount: int) -> void:
	var r := game.rackets
	if amount <= 0 or not poker.sit_down(amount, r.money):
		game.hud.poker_view.close()
		game.player.stand()
		game.mouse(false)
		return
	r.money -= amount
	game.hud.set_purse(r.money, r.bottles, r.held)
	game.hud.poker_view.begin_play()
	game.save()


## Danny gets up from the card table (mid-hand he folds): his chips back into his pocket.
func leave_poker() -> void:
	if not game.hud.poker_view.is_open():
		return
	var r := game.rackets
	var was_seated := poker.seated()
	var before := poker.net
	var chips := poker.leave()
	r.money += chips
	game.hud.poker_view.close()
	game.player.stand()
	game.mouse(false)
	game.hud.set_purse(r.money, r.bottles, r.held)
	if was_seated:
		var won := poker.net - before
		game.hud.show_notice("You get up from the table %s." % (
			"%s ahead" % Rackets.dollars(won) if won > 0 else ("%s down" % Rackets.dollars(-won) if won < 0 else "even")))
	sync_card_players()
	game.save()


func poker_taunt(beat: Dictionary) -> void:
	if poker.table == null:
		return
	for want in PokerTaunts.situations(beat, poker.table, poker.danny):
		if taunt_rng.randf() > 0.35:
			continue
		var line := PokerTaunts.pick(String(want.player), String(want.situation), taunt_rng)
		if line.is_empty():
			continue
		var audio := PokerTaunts.audio_name(line)
		var recorded := game.resolver.has_audio_override(audio) or AssetResolver.audio_fallback_path(audio) != ""
		last_taunt = {"player": want.player, "situation": want.situation, "line": line, "recorded": recorded}
		if recorded and not game.voice.speaking():
			game.soundscape.play(audio, -2.0)
		return  # one at a time


## The card players in their chairs: whoever is still about tonight; the late
## man in the chair of the first to go home.
func sync_card_players() -> void:
	var view := game.interiors.view_of("back_room")
	if view == null:
		return
	var free_chair := {}
	for p in PokerNight.REGULARS:
		var w: Walker = view.people.get(p.id)
		var here: bool = not poker.gone.has(p.id) and int(poker.purses.get(p.id, 0)) + _chips_of(p.id) > 0
		if w != null and not w.down:
			_present(w, here)
		if not here and free_chair.is_empty():
			free_chair = view.plan.person(p.id)
	var moe: Walker = view.people.get(PokerNight.LATE.id)
	if moe != null and not moe.down:
		var in_game := poker.late_joined and not poker.gone.has(PokerNight.LATE.id)
		if in_game and not free_chair.is_empty() and not moe.visible:
			moe.place(free_chair.pos, free_chair.facing)
			moe.aim_point = (free_chair.pos as Vector2) + Vector2.from_angle(free_chair.facing) * 50.0
		_present(moe, in_game)


func _chips_of(id: String) -> int:
	if not poker.seated():
		return 0
	for st in poker.table.seats:
		if st.get("id", "") == id and not st.out:
			return int(st.stack) + int(st.total)
	return 0


func _present(w: Walker, on: bool) -> void:
	w.visible = on
	w.collision_layer = Layers.PEOPLE if on else 0


# ------------------------------------------------------------------ Leo's wheel (M011, M013)

## M011: E at the wheel's rail in the gaming room: Danny steps up to the
## table and the layout comes up (or why there is no game: no croupier,
## closing time).
func open_roulette() -> void:
	var interiors := game.interiors
	var hud := game.hud
	if hud.roulette_view.is_open() or interiors.current == null or interiors.current.id != "gaming_room":
		return
	var view := interiors.view_of("gaming_room")
	if not view.person_ok("croupier"):
		hud.show_notice("Nobody at the wheel tonight.")
		return
	if wheel.phase == RouletteTable.Phase.CLOSED:
		hud.show_notice("Leo's thrown the cover over the wheel. \"That's all for tonight, Mr. Mercer.\"")
		return
	view.face("croupier", game.walker.global_position)
	game.walker.aim_point = _ward(RiversideInteriors.WHEEL_TABLE)
	_wheel_start = game.rackets.money + roulette.for_save()
	hud.roulette_view.layout_for(get_viewport().get_visible_rect().size)
	hud.roulette_view.open(wheel, game.rackets.money)  # M013: the round as it stands - bet now, or watch
	if not wheel.betting_open():
		hud.roulette_view.say("No more bets on this one. Leo opens the next in a moment.")
	game.mouse(true)


func _wheel_money() -> void:
	game.hud.roulette_view.set_money(game.rackets.money)
	game.hud.roulette_view.refresh()
	game.show_purse()


## M013: chips go down, move or come back only while Leo has the bets open.
func _wheel_refuses() -> bool:
	if wheel.betting_open():
		return false
	game.hud.roulette_view.say("\"No more bets.\" Wait for Leo to open the next round." if wheel.phase != RouletteTable.Phase.CLOSED
		else "\"That's the last spin of the night, Mr. Mercer.\"")
	return true


## Chips on a bet (the layout asked for it).
func bet(key: String, chip: int) -> void:
	if _wheel_refuses():
		return
	var r := game.rackets
	var why := roulette.refuse(key, chip, r.money)
	if why != "":
		game.hud.roulette_view.say(why)
		return
	r.money -= roulette.place(key, chip, r.money)
	wheel.touch()  # Leo waits on a man still putting chips down
	game.hud.roulette_view.say("%s on %s." % [RouletteView._chip_words(chip), Roulette.words(key)])
	game.soundscape.play("roulette/chips", -5.0)
	_wheel_money()


func take_back(key: String, chip: int) -> void:
	if _wheel_refuses():
		return
	var back := roulette.remove(key, chip)
	if back > 0:
		game.rackets.money += back
		wheel.touch()
		game.soundscape.play("roulette/chips", -7.0)
		_wheel_money()


func clear_bets() -> void:
	if _wheel_refuses():
		return
	var back := roulette.clear()
	if back > 0:
		game.rackets.money += back
		wheel.touch()
		game.hud.roulette_view.say("You take your chips back.")
		game.soundscape.play("roulette/chips", -5.0)
		_wheel_money()


func repeat_bets() -> void:
	if _wheel_refuses():
		return
	var taken := roulette.repeat(game.rackets.money)
	if taken <= 0:
		game.hud.roulette_view.say("Nothing to put down again." if roulette.last_bets.is_empty() or not roulette.bets.is_empty()
			else "You haven't the money to bet the same again.")
		return
	game.rackets.money -= taken
	wheel.touch()
	game.hud.roulette_view.say("The same again: %s on the table." % Rackets.dollars(taken))
	game.soundscape.play("roulette/chips", -5.0)
	_wheel_money()


## M013: Leo's wheel goes round while Danny is in the gaming room (at the rail
## or anywhere in it; nobody runs it for an empty room): the round moves on,
## the wheel in the room turns as the one on screen does, and the round's
## events are acted on - the money moved once when the ball comes to rest.
func _wheel_update(delta: float) -> void:
	var interiors := game.interiors
	if interiors.current == null or interiors.current.id != "gaming_room":
		return
	var view := interiors.view_of("gaming_room")
	if view == null:
		return
	if not view.person_ok("croupier"):
		if wheel.phase != RouletteTable.Phase.CLOSED:
			game.rackets.money += wheel.halt()  # no croupier, no wheel: what is owed is settled
			game.show_purse()
		return
	for e in wheel.advance(delta):
		_on_wheel_event(e)
	if wheel.phase == RouletteTable.Phase.DROP and not _drop_heard and wheel.round_time - wheel.close_time() > 0.35:
		_drop_heard = true
		_wheel_sound("roulette/ball_drop", -2.0)
	var rotor := view.get_node_or_null("roulette_rotor") as Sprite2D
	if rotor != null:
		rotor.rotation = wheel.motion.rotor


func _on_wheel_event(e: Dictionary) -> void:
	var rv := game.hud.roulette_view
	match String(e.event):
		"open":
			_drop_heard = false
			_wheel_sound("roulette/cue", -12.0)  # Leo's bell: place your bets
			_leo_says(["\"Place your bets, ladies and gentlemen.\"", "\"Faites vos jeux.\"", "\"Bets, please.\""])
		"ball":
			_wheel_sound("roulette/spin", -3.0)
		"patron_bet":
			_wheel_sound("gaming/chips_stack", -10.0)  # a regular's chips going down (not Danny's own sound)
			if rv.is_open():
				rv.refresh()
		"last_call":
			if rv.is_open():
				rv.say("\"Last bets...\"")
		"no_more_bets":
			_wheel_sound("roulette/cue", -9.0)
			if rv.is_open():
				rv.say("\"No more bets.\"")
			_leo_says(["\"No more bets.\"", "\"Rien ne va plus.\""])
			var leo_w: Walker = game.interiors.view_of("gaming_room").people.get("croupier")
			if leo_w != null:
				leo_w.aim_point = _ward(RiversideInteriors.wheel_centre())  # his hand over the wheel as he calls it
		"rest":
			var paid := int(e.paid)
			game.rackets.money += paid  # once: the table settles each round once
			_wheel_sound("roulette/ball_rest", -4.0)
			if bool(e.played):
				_wheel_sound("roulette/win" if paid > 0 else "roulette/lose", -3.0 if paid > 0 else -5.0)
			if rv.is_open():
				rv.show_result(paid, bool(e.played), e.get("others", []))
				rv.set_money(game.rackets.money)
			game.show_purse()
			wheel_reactions(int(e.number), e.get("others", []))
			for id in _unseat_later:  # M013.6: regulars who left once their chips were called
				wheel_patrons.unseat(id)
			_unseat_later.clear()
			if bool(e.played):
				game.save()
		"round_over":
			if rv.is_open():
				rv.refresh()
			var room := game.interiors.view_of("gaming_room")
			if room != null:
				room.face_home()  # Leo back to his place, preparing the next round
		"closed":
			if rv.is_open():
				rv.say("\"That's the last spin of the night, ladies and gentlemen.\"")


## M013.3: the regulars take it as they take it (a line over a head now and
## then - always for a big win - a hop for a win, a turn away for a loss), and
## Leo calls the number, and names a big winner. Presentation only.
func wheel_reactions(number: int, others: Array) -> void:
	var interiors := game.interiors
	var view := interiors.view_of("gaming_room")
	if view == null or interiors.current == null or interiors.current.id != "gaming_room":
		return
	var said := 0
	var leo: Walker = view.people.get("croupier")
	var words := "%d, %s." % [number, "green" if number == 0 else Roulette.colour(number)]
	var big := ""
	for o in others:
		var w: Walker = view.people.get(o.id)
		if w == null or w.down or not view.person_ok(o.id):
			continue
		var net := int(o.paid) - int(o.staked)
		var kind := "big_win" if int(o.paid) >= 10 * int(o.staked) and int(o.paid) >= 100 else ("win" if net > 0 else "lose")
		var chance := 1.0 if kind == "big_win" else (0.55 if kind != "lose" else 0.3)
		if kind == "big_win":
			big = String(o.id)
		if net > 0:
			_hop(w)
		elif net < 0:
			var spot: String = room_life.here.get(String(o.id), "")
			if spot != "":
				_turn_away(w, {"pos": GamingRoomLife.spot_pos(spot), "facing": GamingRoomLife.spot_facing(spot)})
		if said < 2 and react_rng.randf() < chance:
			room_lines.say(w, Patrons.line(String(o.id), kind, react_rng))
			said += 1
	if leo != null and not game.hud.roulette_view.is_open():
		room_lines.say(leo, words + ("  Well played, %s." % Patrons.name_of(big) if big != "" else ""))
	if leo != null and big != "":
		var bw: Walker = view.people.get(big)
		leo.aim_point = bw.global_position  # Leo turns to the winner, then back to his wheel
		var t := create_tween()
		t.tween_interval(2.5)
		t.tween_callback(view.face_home)


## M013.3: Leo's call over his head, for a man watching from the room (at the
## rail the words are on the table's screen) - now and then, not every round.
func _leo_says(lines: Array) -> void:
	var interiors := game.interiors
	if game.hud.roulette_view.is_open() or interiors.current == null or interiors.current.id != "gaming_room":
		return
	var leo: Walker = interiors.view_of("gaming_room").people.get("croupier")
	if leo != null and react_rng.randf() < 0.6:
		room_lines.say(leo, String(lines[react_rng.randi_range(0, lines.size() - 1)]))


## A winner's little hop (the sprite up and back).
func _hop(w: Walker) -> void:
	var t := create_tween()
	t.tween_property(w.sprite, "scale", w.base_scale * 1.14, 0.12)
	t.tween_property(w.sprite, "scale", w.base_scale, 0.22)


## A loser turns from the table a moment, then back.
func _turn_away(w: Walker, home: Dictionary) -> void:
	if home.is_empty():
		return
	w.aim_point = w.global_position - Vector2.from_angle(float(home.facing)).rotated(0.6) * 50.0
	var t := create_tween()  # (dies with the scene, never outliving the people it turns)
	t.tween_interval(1.6)
	t.tween_property(w, "aim_point", (home.pos as Vector2) + Vector2.from_angle(float(home.facing)) * 50.0, 0.0)


## M013.6: the gaming room's life runs while Danny is in it (and only then:
## walking in, everyone is where the evening's schedule has them).
func _room_life_update(delta: float) -> void:
	var interiors := game.interiors
	var inside := interiors.current != null and interiors.current.id == "gaming_room"
	if inside and not _in_gaming_room:
		room_life.enter(game.clock.minute)
	_in_gaming_room = inside
	if inside:
		room_life.update(delta, game.clock.minute, game.walker.global_position, slot_at if game.hud.slot_view.is_open() else -1)


## M013.6: a regular steps up to the rail (his colour chips with the round) or
## leaves it (chips already called ride on until the ball rests).
func _on_patron_at_wheel(id: String, on: bool) -> void:
	if on:
		_unseat_later.erase(id)
		wheel_patrons.seat(id)
	elif wheel.phase == RouletteTable.Phase.DROP:
		if not id in _unseat_later:
			_unseat_later.append(id)
	else:
		wheel_patrons.unseat(id)


## A sound of the wheel: on the table's own channel at the rail, from the
## table's place in the room otherwise.
func _wheel_sound(id: String, db: float) -> void:
	if game.hud.roulette_view.is_open():
		game.soundscape.play(id, db)
	else:
		game.soundscape.play_at(id, _ward(RiversideInteriors.wheel_centre()), db - 7.0)


## Danny walks away from the wheel: chips not yet called come back; a number
## already drawn is settled at once. Leo's round goes on without him.
func leave_roulette() -> void:
	var hud := game.hud
	if not hud.roulette_view.is_open():
		return
	var r := game.rackets
	r.money += roulette.walk_away()
	wheel.left()
	hud.roulette_view.close()
	game.interiors.view_of("gaming_room").face_home()
	game.mouse(false)
	game.show_purse()
	var net := r.money - _wheel_start
	hud.show_notice("You step away from the wheel %s." % (
		"%s ahead" % Rackets.dollars(net) if net > 0 else ("%s down" % Rackets.dollars(-net) if net < 0 else "even")))
	game.save()


# ------------------------------------------------------------------ the machines (M011, M013)

## M011: a machine's sounds: the lever, the reels running (one loop, never
## doubled) until the last one stops, each stop, a coin a coin, the bell for a good win.
func _on_slot_sound(kind: String) -> void:
	var s := game.soundscape
	match kind:
		"lever":
			s.play("slots/lever", -3.0)
		"reels":
			s.start_loop("reels", "slots/reels", -9.0)
		"stop":
			s.play("slots/stop", -4.0)
		"stop_last":
			s.play("slots/stop", -3.0)
			s.stop_loop("reels")
		"coin":
			s.play("slots/coin", -7.0)
		"win":
			if slot_at >= 0 and slot_machines[slot_at].win >= slot_machines[slot_at].rules.coin * 10:
				s.play("slots/bell", -6.0)
		"lamps":
			s.play("slots/lamp", -6.0)  # M013: the HOLD lamps light


## M011: E at one of the machines: Danny steps up to it (the gaming room closes
## at the hour to go home, like the card game).
func open_slot(i: int) -> void:
	var interiors := game.interiors
	if at_a_game() or i < 0 or i >= slot_machines.size() or interiors.current == null or interiors.current.id != "gaming_room":
		return
	if game.clock.minute >= float(game.night_rules.home_minute):
		game.hud.show_notice("Somebody's thrown a cloth over the machines for the night.")
		return
	slot_at = i
	_slot_start = game.rackets.money
	game.walker.aim_point = _ward(RiversideInteriors.SLOTS[i])
	game.hud.slot_view.layout_for(get_viewport().get_visible_rect().size)
	game.hud.slot_view.open(slot_machines[i], game.rackets.money)
	game.mouse(true)


## A pull of the lever (the stake taken once).
func pull() -> void:
	if slot_at < 0:
		return
	var m := slot_machines[slot_at]
	var sv := game.hud.slot_view
	if sv.phase in ["spinning", "stopped"]:
		return
	if game.clock.minute >= float(game.night_rules.home_minute):
		sv.say("That's the last pull of the night.")
		return
	var why := m.cannot_pull(game.rackets.money)
	if why != "":
		sv.say(why)
		return
	game.rackets.money -= m.pull(game.rackets.money, slot_rng.randi())
	sv.set_money(game.rackets.money)
	game.show_purse()
	sv.start_reels()


## M013: a reel held for the next pull, or let go (under lit HOLD lamps).
func hold(reel: int) -> void:
	var sv := game.hud.slot_view
	if slot_at < 0 or sv.phase in ["spinning", "stopped"]:
		return
	var m := slot_machines[slot_at]
	var why := m.toggle_hold(reel)
	if why != "":
		sv.say(why)
		return
	game.soundscape.play("slots/hold" if m.held[reel] else "slots/release", -4.0)
	var held := []
	for r in 3:
		if m.held[r]:
			held.append("%s on reel %d" % [SlotMachine.WORDS[m.symbol(r, m.stops[r])], r + 1])
	sv.say("Holding " + " and ".join(held) + ". Pull for %s." % PokerView.money_text(m.stake) if not held.is_empty()
		else "No reels held: the next pull spins all three.")


## M013: the stake for the next pull (under lit lamps a change puts them out).
func set_stake(cents: int) -> void:
	var sv := game.hud.slot_view
	if slot_at < 0 or sv.phase in ["spinning", "stopped"]:
		return
	var m := slot_machines[slot_at]
	var had_lamps := m.hold_offered
	var why := m.set_stake(cents)
	if why != "":
		sv.say(why)
		return
	game.soundscape.play("slots/release" if had_lamps and not m.hold_offered else "slots/hold", -9.0)
	sv.say("%s a pull: the plate pays in proportion.%s" % [PokerView.money_text(m.stake),
		"  (The HOLD lamps go out with the change.)" if had_lamps and not m.hold_offered else ""])


## The reels have stopped: the line is paid, once.
func _on_slot_stopped() -> void:
	if slot_at < 0:
		return
	var paid := slot_machines[slot_at].collect()
	game.rackets.money += paid
	game.hud.slot_view.set_money(game.rackets.money)
	game.hud.slot_view.show_paid(paid)
	game.show_purse()
	game.save()


## Danny steps away from the machine: a pull under way is paid at once.
func leave_slot() -> void:
	var hud := game.hud
	if not hud.slot_view.is_open():
		return
	var r := game.rackets
	if slot_at >= 0:
		r.money += slot_machines[slot_at].walk_away()
	game.soundscape.stop_loop("reels")
	hud.slot_view.close()
	slot_at = -1
	game.mouse(false)
	game.show_purse()
	var net := r.money - _slot_start
	hud.show_notice("You step away from the machine %s." % (
		"%s ahead" % Rackets.dollars(net) if net > 0 else ("%s down" % Rackets.dollars(-net) if net < 0 else "even")))
	game.save()
