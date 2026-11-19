class_name SlotRules
extends Resource
## One of the gaming room's nickel machines (slot_owl.tres, slot_bell.tres,
## slot_star.tres): its name, its coin, its three reels and the paytable on
## its front. Every machine runs on the same SlotMachine; only this differs.
## PROVISIONAL, to be tuned by playing (test_slot_machine prints each
## machine's exact return).

@export var title := "The Owl"
## The coin it takes for a pull (cents).
@export var coin := 5
## The three reels, top to bottom as they pass the window: twenty stops each,
## each stop a symbol (cherry, lemon, orange, plum, bell, bar, seven).
@export var strips: Array[PackedStringArray] = []
## The paytable, best first; the first line the reels show that matches pays
## (in coins). "*" is any symbol. Printed on the machine's front as it is here.
@export var pays: Array[Dictionary] = []
## Seconds after the lever is pulled that each reel stops (presentation).
@export var stop_times: PackedFloat32Array = PackedFloat32Array([1.1, 1.6, 2.15])
