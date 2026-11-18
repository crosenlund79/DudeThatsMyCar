class_name FightRules
extends Resource
## How a fistfight's timing checks behave (default_fight.tres). Every number
## is PROVISIONAL and meant to be tuned by playing.

## Checks in a fight, and how many Danny must win to win the fight.
@export var checks := 5
@export var wins_needed := 3
## How fast the needle sweeps the dial (degrees a second) and by how much it
## may vary from one check to the next (a fraction, either way).
@export var needle_speed := 250.0
@export var speed_variation := 0.12
## The width of the lit zone on the dial (degrees) and how far round the
## dial it may start (degrees from the top, where the needle starts).
@export var zone_width := 64.0
@export var zone_earliest := 120.0
@export var zone_latest := 290.0
## A breath before each check (the dial resets), and how long the result shows.
@export var lead_in := 0.55
@export var feedback := 0.5
