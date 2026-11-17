class_name GunRules
extends Resource
## One handgun's behaviour (default_pistol.tres). Every number is PROVISIONAL.
## The pistol is a .45 automatic: seven rounds, one shot per click.

@export var display_name := ".45 automatic"
## Rounds in a magazine; an empty gun reloads by itself from the spare rounds.
@export var magazine := 7
## Spare rounds carried at the start (-1 = never run out, as in M002). More
## can be bought from Eddie in the back of the hardware store (M003).
@export var spare_rounds := -1
## Seconds between shots; reloading time; drawing from under the coat.
@export var fire_interval := 0.28
@export var reload_time := 1.5
@export var draw_time := 0.18
## The gun goes back under the coat after this long without a shot.
@export var holster_after := 5.0
## A click this soon before the gun is ready (drawing, cooling down) still fires.
@export var trigger_buffer := 0.3
## Bullets: speed and reach (world px), and a little scatter (degrees each way).
@export var bullet_speed := 1600.0
@export var bullet_range := 640.0
@export var spread_degrees := 1.2
## How far away a shot is heard (world px).
@export var noise_radius := 720.0
## Where the pistol sits and where its muzzle is, in the shooter's frame
## (facing +X, world px).
@export var hand_offset := Vector2(11, 3)
@export var muzzle_offset := Vector2(23, 3)
