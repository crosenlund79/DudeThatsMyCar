class_name DamageRules
extends Resource
## Vehicle condition and how it wears down (retained from HyperCars; not yet
## wired into the city). Every number is PROVISIONAL and tunable here
## (default_damage_rules.tres). Condition does not change handling; at zero
## the car is wrecked.

## Full condition (100 = 100 %).
@export var max_condition := 100.0
## Wall impacts: speed into the wall (px/s) below the threshold is a scrape and
## costs nothing; above it, damage = (speed - threshold) * factor, at most
## wall_max_damage per impact.
@export var wall_threshold := 110.0
@export var wall_damage_per_speed := 0.05
@export var wall_max_damage := 12.0
## Car-to-car contacts: closing speed (px/s) above the threshold damages BOTH
## cars by (speed - threshold) * factor, at most car_max_damage each. One
## contact between a pair counts once per tick.
@export var car_threshold := 120.0
@export var car_damage_per_speed := 0.02
@export var car_max_damage := 8.0
## At or below this condition the car counts as critical.
@export var critical_condition := 25.0


## Damage from a wall impact at this speed (before armour).
func wall_damage(speed: float) -> float:
	return clampf((speed - wall_threshold) * wall_damage_per_speed, 0.0, wall_max_damage)


## Damage to each car from a contact at this closing speed (before armour).
func car_damage(speed: float) -> float:
	return clampf((speed - car_threshold) * car_damage_per_speed, 0.0, car_max_damage)
