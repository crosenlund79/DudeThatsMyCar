class_name PoliceRules
extends Resource
## How the beat cop behaves (default_police.tres). Every number is PROVISIONAL.

## Walking his beat, running after you, searching (world px per second).
## He runs a touch slower than you walk, so you can get away on foot by
## breaking his line of sight; a car loses him easily.
@export var patrol_speed := 60.0
@export var chase_speed := 104.0
@export var search_speed := 78.0
## How far he sees at night, and how far a shot carries for him
## (the gun's own noise radius applies too: the smaller of the two).
## M010: 960 px, so the Thompson (950) carries further than a .45 (720).
@export var sight_range := 430.0
@export var hearing_range := 960.0
## Seconds he freezes, turns and blows his whistle when he notices gunfire.
@export var alert_time := 0.7
## After losing sight of you: seconds he keeps looking round the last place
## he saw you before he gives up and walks back to his beat.
@export var search_time := 8.0
## How far past the last sighting he follows the way you were heading.
@export var follow_through := 140.0
## Pause at each end of his beat (s).
@export var beat_pause := 2.5
## He stops this close to you (no arrests yet).
@export var close_distance := 30.0
## M008: armed response. He draws his revolver only after he has seen a
## serious violent crime tonight (you shot somebody where he could see, or
## you shot at him); gunfire he only hears gets the old unarmed pursuit.
## Then: the distance he keeps, when he backs off, how far he fires, the
## seconds between his shots (plus up to the jitter), and the delay before
## the first shot after drawing or getting you back in sight (a warning).
@export var armed_keep_at := 230.0
@export var armed_too_close := 100.0
@export var fire_range := 380.0
@export var fire_gap := 1.8
@export var fire_jitter := 0.9
@export var first_shot := 1.2
## Running while armed (he does not shoot on the run: he stops to fire).
@export var armed_move_speed := 96.0
