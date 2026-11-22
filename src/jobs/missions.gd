class_name Missions
extends RefCounted
## M014: every authored job and opportunity in the game, run the same way: each
## is a JobDirector, added once in a fixed order; Missions hands their effects
## to Dialogue, their fights to Fights, and calls their hooks (the clock, a new
## night, rooms built, a restored game) in that order - so a job never needs a
## line in main. The order is the one M007-M012 had in main's clock: the Lefty
## job, Dutch's crate and the Bijou's reel, the freight, the cafe, the Bird's
## last song.

var game: Game
var jobs: Array[JobDirector] = []
var _starters := {}


func _init(p_game: Game) -> void:
	game = p_game


## Adds a job: its effects and fights are registered at once (an effect or a
## fight another job already has is refused).
func add(job: JobDirector) -> JobDirector:
	assert(not jobs.has(job), "a job added twice")
	jobs.append(job)
	var fx := job.effects()
	for key in fx:
		game.dialogue.on_effect(key, fx[key])
	var f := job.fights()
	for who in f:
		assert(not _starters.has(who), "two jobs start a fight with " + who)
		_starters[who] = f[who]
	return job


func get_job(job_id: String) -> JobDirector:
	for j in jobs:
		if j.id() == job_id:
			return j
	return null


## What starts a fight agreed in a talk with `who` (an invalid Callable if no job has one).
func fight_starter(who: String) -> Callable:
	return _starters.get(who, Callable())


func setup() -> void:
	for j in jobs:
		j.setup()


func clock(minute: float, delta: float) -> void:
	for j in jobs:
		j.clock(minute, delta)


func district_ready(id: String, layout: DistrictLayout, node: Node2D) -> void:
	for j in jobs:
		j.district_ready(id, layout, node)


func district_unloading(id: String) -> void:
	for j in jobs:
		j.district_unloading(id)


func rooms_built() -> void:
	for j in jobs:
		j.rooms_built()


func new_night() -> void:
	for j in jobs:
		j.new_night()


func restored() -> void:
	for j in jobs:
		j.restored()


func busy() -> bool:
	return jobs.any(func(j: JobDirector) -> bool: return j.busy())
