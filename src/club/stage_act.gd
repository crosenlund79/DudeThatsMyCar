class_name StageAct
extends RefCounted
## The Bird's act on the Copper Owl's bandstand (pure, no scene): she sings
## until Danny interrupts her, stops while they talk, and a moment after he
## walks away the band counts her back in and she starts her number again.
## Only a singing Bird can be interrupted, so there is one scratch per
## interruption and the song never starts twice.

enum State { SINGING, STOPPED, RESUMING }

## Seconds between the end of the talk and the song starting again.
const RESUME_DELAY := 2.5

var state := State.SINGING
var resume_left := 0.0
## M006: she was shot and carried off: no more singing tonight.
var out := false
## Times Danny has stopped her song tonight.
var interruptions := 0


func singing() -> bool:
	return state == State.SINGING


## M012: her last song of the night is over - she is done until tomorrow.
var done := false


func finish() -> void:
	done = true
	state = State.STOPPED


## Danny walks up to her while she sings: the song stops. False (and nothing
## happens) when she is not singing.
func interrupt() -> bool:
	if state != State.SINGING:
		return false
	state = State.STOPPED
	interruptions += 1
	return true


## Danny talks to her between songs: she waits for him.
func hold() -> void:
	if state == State.RESUMING:
		state = State.STOPPED


## Shot down on the bandstand: the song stops and she is gone for the night.
func knock_out() -> void:
	out = true
	state = State.STOPPED


## The talk is over: she goes back to the microphone.
func release() -> void:
	if state == State.STOPPED and not out and not done:
		state = State.RESUMING
		resume_left = RESUME_DELAY


## Time passes. Returns true at the moment the song should start again.
func update(delta: float) -> bool:
	if state != State.RESUMING:
		return false
	resume_left -= delta
	if resume_left > 0.0:
		return false
	state = State.SINGING
	return true


## A new night: she is singing when the club opens.
func reset() -> void:
	interruptions = 0
	out = false
	done = false
	if state != State.SINGING:
		state = State.RESUMING
		resume_left = 0.0
