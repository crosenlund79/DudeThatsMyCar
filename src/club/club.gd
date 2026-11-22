class_name Club
extends RefCounted
## M014 (from main): the Copper Owl's bandstand in the game (M006) - E at the
## Bird's microphone interrupts her song (the needle scratches off the record,
## she remembers who stopped it) or catches her between songs; when he walks
## away the band counts her back in. Her act is the pure StageAct; how she
## moves is BirdPerformance.

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## E at the Bird's microphone: if she is singing, the needle scratches off the
## record, the song stops and she gives Danny a piece of her mind; between
## songs she just waits for him. Either way they talk, and when he walks away
## the band counts her back in.
func talk_to_bird() -> void:
	var stage := game.stage
	var interrupted := stage.interrupt()
	if interrupted:
		game.soundscape.interrupt_music()
		game.rackets.memory.remember("bird", "interrupted", game.rackets.night)  # M012: she remembers who stopped her song
	else:
		stage.hold()
	game.dialogue.start("bird", {"interrupted": interrupted})


## A talk ended: if it was with the Bird, the band can count her back in.
func talk_ended(who: String) -> void:
	if who == "bird":
		game.stage.release()


## Every frame the world runs: the band counts her back in when it is time.
func update(delta: float) -> void:
	if game.stage.update(delta):
		game.soundscape.resume_music()  # the band counts her back in
		if game.bird_show != null:
			game.bird_show.restart()


## A new night: she is singing when the club opens.
func new_night() -> void:
	game.stage.reset()
