class_name EconomyRules
extends Resource
## Prices and limits of the Riverside Ward's small criminal economy. Money is
## in cents. Nightly limits stop any one deal from paying out over and over:
## they reset only when the player sleeps. ALL VALUES PROVISIONAL.

## Money in your pocket on the very first night.
@export var start_money := 1200
## Most bottles you can carry under a coat.
@export var carry_limit := 6

@export_group("Bootleg rye")
## Sal the barber sells at this price, this many bottles a night.
@export var barber_price := 150
@export var barber_stock := 6
## Augie at the Copper Owl buys at this price, this many bottles a night;
## after you have leaned on him for protection he pays the lower price that night.
@export var bar_price := 300
@export var bar_price_sore := 225
@export var bar_demand := 6

@export_group("Protection")
## What a business pays once a night: asked politely / leaned on.
@export var bar_protection := 1000
@export var bar_protection_leaned := 1500
@export var grocer_protection := 500
@export var grocer_protection_leaned := 800

@export_group("Ammunition")
## Eddie in the back of the hardware store: a box of .45 rounds.
@export var ammo_price := 250
@export var ammo_box := 14
## Most spare rounds you can carry.
@export var spare_limit := 42
