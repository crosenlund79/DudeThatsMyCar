extends GutTest
## M013 the hooks for recorded card-table taunts (PokerTaunts, pure data):
## every card player has a line for every situation, each with an id, words
## and a delivery note, under its own voice name; the recording draft
## (docs/POKER_TAUNTS.md) lists every line; what a beat means is read right
## (a fold, a raise, a bet with nothing made, the result); nothing ships
## recorded, so nothing would play.


func test_every_player_every_situation() -> void:
	var ids := {}
	for p in ["irv", "red", "pete", "moe"]:
		for sit in PokerTaunts.SITUATIONS:
			var lines: Array = PokerTaunts.LINES[p].get(sit, [])
			assert_false(lines.is_empty(), "%s has a line for %s" % [p, sit])
			for l in lines:
				assert_ne(String(l.text), "")
				assert_ne(String(l.note), "", "a delivery note for whoever records it")
				assert_false(ids.has(l.id), "%s is one line" % l.id)
				ids[l.id] = true
				assert_eq(PokerTaunts.audio_name(l), "voice/poker/" + String(l.id))
				assert_eq(AssetResolver.audio_fallback_path(PokerTaunts.audio_name(l)), "", "nothing recorded or synthesised ships")


func test_the_recording_draft_lists_every_line() -> void:
	var doc := FileAccess.get_file_as_string("res://docs/POKER_TAUNTS.md")
	for p in PokerTaunts.LINES:
		for sit in PokerTaunts.LINES[p]:
			for l in PokerTaunts.LINES[p][sit]:
				assert_string_contains(doc, "`%s`" % l.id)
				assert_string_contains(doc, String(l.text))


func test_what_a_beat_means() -> void:
	var t := Holdem.new(5, 10, 5)
	t.sit("Danny", 1000, {"id": "danny"})
	t.sit("Red Gallagher", 1000, {"id": "red", "style": "aggressive"})
	t.sit("Irv Feldman", 1000, {"id": "irv", "style": "cautious"})
	t.start_hand(7)
	var s := PokerTaunts.situations({"kind": "action", "seat": 1, "player": "red", "action": "fold"}, t, 0)
	assert_eq(s, [{"player": "red", "situation": "fold"}])
	s = PokerTaunts.situations({"kind": "action", "seat": 1, "player": "red", "action": "raise"}, t, 0)
	assert_eq(s[0].situation, "raise", "before the flop nothing counts as a bluff")
	assert_true(PokerTaunts.situations({"kind": "action", "seat": 0, "player": "danny", "action": "raise"}, t, 0).is_empty(),
		"Danny taunts nobody")
	assert_true(PokerTaunts.situations({"kind": "action", "seat": 2, "player": "irv", "action": "check"}, t, 0).is_empty())
	var rng := RandomNumberGenerator.new()
	assert_has(PokerTaunts.LINES.red.fold, PokerTaunts.pick("red", "fold", rng))
	assert_eq(PokerTaunts.pick("nobody", "fold", rng), {})
