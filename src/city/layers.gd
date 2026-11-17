class_name Layers
extends RefCounted
## Physics layers (bit values) and draw order (z) shared by the city, cars and people.

## Buildings, walls, barricades, railings, lamp posts and other solid props.
const WORLD := 1
## Cars.
const CARS := 2
## People on foot (the player). Cars do not collide with this layer; people
## collide with the world and with cars.
const PEOPLE := 4

## Light masks: street-level things are lit by street lamps and headlights;
## roofs are above the lamps and are not.
const LIGHT_STREET := 1
const LIGHT_ROOF := 2

## Draw order, lowest first. Everything at street level sits below the walls;
## roofs draw in order of height so a taller roof covers a lower one.
const Z_GROUND := -100
const Z_GROUND_DETAIL := -90
const Z_CURB := -85
const Z_DECAL := -80
const Z_SHADOW := -75
const Z_LIGHT_POOL := -70
const Z_REFLECTION := -65
const Z_PROP := -10
const Z_ACTOR := 0
const Z_STEAM := 5
const Z_WALL := 10
const Z_WALL_GLOW := 11
const Z_RAISED := 12
const Z_RAISED_GLOW := 13
const Z_ROOF := 20
const Z_SMOKE := 40
const Z_MIST := 50
