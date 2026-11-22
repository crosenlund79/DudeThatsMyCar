class_name JobDirector
extends RefCounted
## M014: the game side of one authored job or opportunity - what it does in
## the street, in a talk, on the clock and in a film - around its pure model
## (RourkeJob, CafeJob, FreightJob, Opportunities, the Bird's scene in
## Rackets), which keeps the story, the money, the one-time payments and the
## save. Missions calls the hooks below for every job in one fixed order; a
## director overrides only what it needs. Lines and choices stay in the model
## and in Conversations - nothing here is a generic story format.
##
## A new job: a pure model (its stages, what it pays, to_dict / from_dict,
## kept in Rackets), a director extending this, one line in Missions.

var game: Game


func _init(p_game: Game) -> void:
	game = p_game


## A short name for this job (tests, the notebook's order, messages).
func id() -> String:
	return ""


## The effects of a talk's pages this job handles: {key: handler(value, effects)}
## (keys from Dialogue.EFFECTS).
func effects() -> Dictionary:
	return {}


## The fistfights a talk can agree to that are this job's: {who: start()}.
func fights() -> Dictionary:
	return {}


## Wired once the game is built (its views and signals).
func setup() -> void:
	pass


## An E spot this job offers where Danny stands ({} for none). Interactions
## asks each job at its own place in the order of what E does first.
func spot(_at: Vector2) -> Dictionary:
	return {}


## E at the spot this job offered.
func use(_spot: Dictionary) -> void:
	pass


## The night moved on (the game minute; `delta`: real seconds this frame).
func clock(_minute: float, _delta: float) -> void:
	pass


## A streamed district was built (M008): what the job has in it is made.
func district_ready(_id: String, _layout: DistrictLayout, _node: Node2D) -> void:
	pass


## A streamed district is about to be let go: what the job made in it goes too.
func district_unloading(_id: String) -> void:
	pass


## A streamed district's rooms were built (M012).
func rooms_built() -> void:
	pass


## A new night begins (after sleeping).
func new_night() -> void:
	pass


## A saved game was put back (Danny in his place, the cars where they stood).
func restored() -> void:
	pass


## While its film or scene keeps Danny busy (no call-outs, no drowsiness).
func busy() -> bool:
	return false
