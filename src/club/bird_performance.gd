class_name BirdPerformance
extends Node
## How the Bird looks while she sings (presentation only): she sways to the
## song (about 54 beats a minute, a slow ballad: one sway takes two beats),
## changes her gesture every four beats - hands at the microphone, an arm
## out, both arms open, a hand to her heart - and breathes with the phrase.
## When the song stops she stands still and turns to whoever she is talking to.

const BEAT := 60.0 / 54.5
const SWAY := 0.09
## The order of her gestures (sheet frames), one every four beats.
const GESTURES := [0, 1, 0, 2, 0, 3, 4, 0]

var bird: Walker
var stage: StageAct
## Seconds of singing since the song (re)started.
var time := 0.0


func setup(p_bird: Walker, p_stage: StageAct) -> void:
	name = "BirdPerformance"
	bird = p_bird
	stage = p_stage
	bird.animate = false


func restart() -> void:
	time = 0.0


## The gesture (sheet frame) and the sway (radians) at time t of the song.
static func pose_at(t: float) -> Dictionary:
	var gesture: int = GESTURES[int(t / (BEAT * 4.0)) % GESTURES.size()]
	var sway := sin(TAU * t / (BEAT * 2.0)) * SWAY
	var breath := 1.0 + 0.02 * sin(TAU * t / (BEAT * 4.0))
	return {"frame": gesture, "sway": sway, "scale": breath}


func _process(delta: float) -> void:
	if bird == null or not is_instance_valid(bird):
		return
	if stage.singing():
		time += delta
		var p := pose_at(time)
		bird.sprite.frame = p.frame
		bird.sprite.rotation = bird.model.facing + p.sway
		bird.sprite.scale = bird.base_scale * p.scale
	else:
		bird.sprite.frame = 0
		bird.sprite.rotation = bird.model.facing
		bird.sprite.scale = bird.base_scale
