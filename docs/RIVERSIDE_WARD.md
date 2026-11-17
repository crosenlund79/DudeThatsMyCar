# The Riverside Ward (Milestones 001–003)

A few blocks of a fictional Near North Side neighbourhood, Chicago, 1932, at night. Hand-made in `src/city/riverside_ward.gd`; built and drawn by `src/city/city.gd`. North is up. One world pixel is about 7 cm of street.

```
            railroad embankment (stone wall, tracks on top)
   ┌──────────┬───────────────┬───────────────┬──────────┐
   │          │   flats       │   flats       │ ware-    │
 ══╪═ Calloway Street ════════╪═══════════════╪══ house ═╡ river
   │ Dorsey   │ flats·alley   │ flats·alley   │ Lakeshore│ (railing)
   │ Street   │ shops, SAL'S  │ COPPER OWL,   │ Cold     │
   │          │ BARBER SHOP   │ YOUR FLAT     │ Storage  │
 ══╪═ Marlowe Avenue (streetcar tracks) ══════════════════╡ raised
   │          │ LINDQVIST     │ NOVAK'S, HOTEL│ bridge   │ bascule
   │          │ HARDWARE      │ MARLOWE       │ tender   │ bridge
   │          │ flats·alley   │ flats·alley▣  │          │  ▣ squad car
 ══╪═ Pruitt Street ══ DOYLE'S GARAGE ════════╪══════════╡
   │          │               │               │          │
   barricades (west and south ends of the streets)
```

## Streets and places

- **Marlowe Avenue** (east–west, wide, cobbled streetcar tracks down the middle) — the main street: shops with awnings, the **Copper Owl** supper club (dark green tile, copper trim, neon owl on the roof, a lit canopy over the sidewalk) and, across the street, the six-storey **Hotel Marlowe**. You start at the streetcar stop between them.
- **Calloway Street** and **Pruitt Street** (east–west), **Dorsey**, **Kessler** and **Wharf Street** (north–south): flats (red brick and greystone), shops, a few warehouses.
- **Alleys** run east–west through the middle of the central blocks, brick-paved, lined with fire escapes, back doors, ash cans; behind the Copper Owl, a stack of crates and barrels from tonight's delivery.
- **Gangways**: narrow passages between houses (about 26 px). A person fits; a car does not.
- **The beat cop** walks a short round on the north side of Marlowe Avenue by the Kessler Street corner, between the newsstand and his police call box (M002). Shots within earshot bring him running; get out of his sight and he searches, gives up and goes back to his round.
- **Doyle's Garage** on Pruitt Street, with its forecourt, a gas pump and two parked cars.
- **Lakeshore Cold Storage**, a four-storey warehouse on the river at Wharf Street, with a loading apron along the quay (crates, barrels, a parked sedan).
- **The river** along the east side; the **Marlowe Avenue Bridge** is raised for the night (both bascule leaves up), behind gates with red lanterns. Lamps and lit windows on the far bank.

## Rooms you can walk into (Milestone 003)

Doors with warm light on the pavement can be walked through. Inside, the building's roof and walls fade away and the room shows from above, lit by its own lamps; it closes up again as you leave. E talks to whoever is there; answer with 1–4 (or a click), E or Esc walks away.

- **Your Flat** — one ground-floor room in the Marlowe Flats, next door to the Copper Owl: iron bed, rag rug, radio, wardrobe, kitchen table, stove. Every night begins here at 7:30 pm; E at the bed sleeps through to the next evening. Your sedan is parked at the curb outside.
- **The Copper Owl** — front door under the canopy, back door to the alley where the bootleg delivery stands. The bar along the back wall with **Augie** behind it, stools, four tables with guests, a baby grand on the bandstand. Augie buys bootleg rye (six bottles a night) and can be asked — or leaned on — for protection money once a night.
- **Sal's Barber Shop** — a block west on the north side of Marlowe Avenue (red awning, barber's pole, painted roof sign). Two chairs before the mirror, a bench, and the cupboard where **Sal** keeps the rye he sells you (six bottles a night).
- **Novak's Grocery** — on the corner of Kessler Street, south side of Marlowe, across from the beat cop: shelves of tins, produce crates, the counter and till. **Mr. Novak** pays protection once a night; lean on him and he runs out for the copper once you have gone.
- **Lindqvist Hardware** — south side of Marlowe, west of Kessler (green awning). **Mr. Lindqvist** at the front counter; through the inner door, **Eddie**'s back room with a card table and a crate of pistols. Eddie sells boxes of .45 rounds, nothing more.

## The street at night (Milestone 003)

- A clock at the top of the screen: the night begins at 7:30 pm and runs at one minute a second; from 4 am you are told to get home, at 5:30 the clock stops and waits for you to go to bed. There is no daytime.
- Six passers-by stroll the sidewalks of Marlowe Avenue and Kessler Street, stop at shop windows, jump out of the way of a car coming at them and run from gunfire. Three cars with their headlights on go round the hotel and garage blocks on the right-hand lanes, slowing for corners, waiting at the crossings and stopping for anyone in their path. After 11 pm fewer people and cars are out; they come and go only out of sight.
- A black squad car with POLICE across its roof is parked in the alley behind Novak's Grocery.

## Edges

The district is closed by things you can see: the railroad embankment at the north ends of the streets, the river railing and the raised bridge in the east, and street-closed barricades with warning lanterns where the streets carry on west and south. The city keeps going visually beyond them.

## Cars

Eight parked cars of two kinds, each in two paint schemes, and the squad car (sedan handling):

| Car | Look | Handling (M003, provisional) |
| --- | --- | --- |
| **Roadster** (`coupe`) | long hood, boat tail, open cockpit, side-mounted spares; cream with maroon wings, or green and black | quicker (top speed 370 px/s, about 62 mph), a tighter turning circle (73 px), a little more cornering grip, a looser tail on the handbrake |
| **Sedan** (`sedan`) | four-door, closed cabin, spare on the back; bottle green or wine red | heavier (330 px/s, about 55 mph), slower to pull away, a wider circle (77 px), more planted |

Since Milestone 003 both steer like road cars: the front wheels (you can see them turn, even standing still) set the circle the car follows, so it turns in proportion to how fast it rolls, pivots round its rear axle, reverses the other way round, runs wide if you take a corner too fast and only slides on the handbrake. The engine and the brakes build up over a fraction of a second; lifting off, the car rolls on. A shallow scrape along a wall keeps most of the speed and eases the nose along the wall. A parked car can be shoved and stops on its handbrake. Three more cars drive round the blocks (see above); they cannot be taken.

## How it is drawn

The camera looks straight down. A room you are standing in is drawn as a cut-away: its house's walls, roof and rooftop signs fade out, the floor, furniture, people and warm lamps show; the closed rest of the house keeps its roof. Everything raised above the street is drawn where a camera that height would see it: walls lean away from the centre of the screen and show their facades, taller buildings lean more, roofs carry chimneys, vents, skylights, stair huts, water tanks, washing and signs, fire escapes stack out from the walls. Street lamps light the pavement and the cars and leave wet reflections that stream towards the middle of the screen; windows, signs and lamps glow on their own; steam rises from manholes and smoke from a few chimneys under a cool night tint and a soft vignette.
