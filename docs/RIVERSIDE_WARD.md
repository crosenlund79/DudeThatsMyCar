# The Riverside Ward (Milestone 001)

A few blocks of a fictional Near North Side neighbourhood, Chicago, 1932, at night. Hand-made in `src/city/riverside_ward.gd`; built and drawn by `src/city/city.gd`. North is up. One world pixel is about 7 cm of street.

```
            railroad embankment (stone wall, tracks on top)
   ┌──────────┬───────────────┬───────────────┬──────────┐
   │          │   flats       │   flats       │ ware-    │
 ══╪═ Calloway Street ════════╪═══════════════╪══ house ═╡ river
   │ Dorsey   │ flats·alley   │ flats·alley   │ Lakeshore│ (railing)
   │ Street   │ shops         │ shops, COPPER │ Cold     │
 ══╪═ Marlowe Avenue (streetcar tracks) ═════ OWL ═══════╡ raised
   │          │ shops         │ HOTEL MARLOWE │ bridge   │ bascule
   │          │ flats·alley   │ flats·alley   │ tender   │ bridge
 ══╪═ Pruitt Street ══ DOYLE'S GARAGE ════════╪══════════╡
   │          │               │               │          │
   barricades (west and south ends of the streets)
```

## Streets and places

- **Marlowe Avenue** (east–west, wide, cobbled streetcar tracks down the middle) — the main street: shops with awnings, the **Copper Owl** supper club (dark green tile, copper trim, neon owl on the roof, a lit canopy over the sidewalk) and, across the street, the six-storey **Hotel Marlowe**. You start at the streetcar stop between them.
- **Calloway Street** and **Pruitt Street** (east–west), **Dorsey**, **Kessler** and **Wharf Street** (north–south): flats (red brick and greystone), shops, a few warehouses.
- **Alleys** run east–west through the middle of the central blocks, brick-paved, lined with fire escapes, back doors, ash cans; behind the Copper Owl, a stack of crates and barrels from tonight's delivery.
- **Gangways**: narrow passages between houses (about 26 px). A person fits; a car does not.
- **Doyle's Garage** on Pruitt Street, with its forecourt, a gas pump and two parked cars.
- **Lakeshore Cold Storage**, a four-storey warehouse on the river at Wharf Street, with a loading apron along the quay (crates, barrels, a parked sedan).
- **The river** along the east side; the **Marlowe Avenue Bridge** is raised for the night (both bascule leaves up), behind gates with red lanterns. Lamps and lit windows on the far bank.

## Edges

The district is closed by things you can see: the railroad embankment at the north ends of the streets, the river railing and the raised bridge in the east, and street-closed barricades with warning lanterns where the streets carry on west and south. The city keeps going visually beyond them.

## Cars

Seven parked cars of two kinds, each in two paint schemes:

| Car | Look | Handling (provisional, close to HyperCars) |
| --- | --- | --- |
| **Roadster** (`coupe`) | long hood, boat tail, open cockpit, side-mounted spares; cream with maroon wings, or green and black | quicker (top speed 440, acceleration 285), sharper steering, a looser tail (grip 4.1) |
| **Sedan** (`sedan`) | four-door, closed cabin, spare on the back; bottle green or wine red | heavier and more planted (400, 235, grip 4.9), a little slower to turn |

Both brake with S and then reverse, steer more gently at walking pace and the other way round when reversing, and slide on the handbrake. A parked car can be shoved and stops on its handbrake.

## How it is drawn

The camera looks straight down. Everything raised above the street is drawn where a camera that height would see it: walls lean away from the centre of the screen and show their facades, taller buildings lean more, roofs carry chimneys, vents, skylights, stair huts, water tanks, washing and signs, fire escapes stack out from the walls. Street lamps light the pavement and the cars and leave wet reflections that stream towards the middle of the screen; windows, signs and lamps glow on their own; steam rises from manholes and smoke from a few chimneys under a cool night tint and a soft vignette.
