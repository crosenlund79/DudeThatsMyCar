class_name EconomyRules
extends Resource
## Prices and limits of Danny's dealings (default_economy.tres). Money is in
## cents. What the businesses hold, sell and pay lives in their own state
## (Neighbourhood, Business); these are the prices they deal with Danny at.
## ALL VALUES PROVISIONAL.

## Money in your pocket on the very first night.
@export var start_money := 1200
## Most bottles you can carry under a coat.
@export var carry_limit := 6

@export_group("Bootleg rye")
## Sal sells at this price; more when his cupboard is nearly bare, less when
## it is full.
@export var barber_price := 150
@export var barber_price_scarce := 200
@export var barber_price_plenty := 130
## Augie buys at this price; more when the cellar is running dry, less when
## it is nearly full, and less the night you have leaned on him.
@export var bar_price := 300
@export var bar_price_dry := 375
@export var bar_price_full := 250
@export var bar_sore_discount := 75

@export_group("Ammunition")
## Eddie in the back of the hardware store: a box of .45 rounds.
@export var ammo_price := 250
@export var ammo_box := 14
## Most spare rounds you can carry.
@export var spare_limit := 42
