# Manual playtest checklist - Milestone 013: The House Always Wins

Play `src/main/main.tscn` with keyboard, mouse and headphones, ideally on a real graphics card and at your usual window size (full screen too), over a night or two - one of them wet. Tick each item; note problems in `docs/BACKLOG.md` (not as tasks).

## Cars and saving
- [ ] Drive any car into Halloran Square (or the yards), Esc, Save the game, quit, start again: you are behind the same wheel, where the car stood and facing the same way; drive off at once. The camera is on the car.
- [ ] Leave a car in the street, walk away (far enough that its district goes), come back: it is where you left it. Save and load beside it: still there.
- [ ] Take somebody else's car, save in it, load: still in it; no second "theft" notice.
- [ ] Sleep: the next evening every car is back with its owner (your sedan outside your flat).

## Rain
- [ ] Steady rain on Marlowe Avenue: the streaks fall down and lean a little with the wind; nothing runs upwards; no doubled streaks side by side; no rows of drops marching in step; no pattern repeating across the screen. Compare with the earlier look you preferred (`docs/screenshots/m010/weather_rain.png`).
- [ ] Wait for a downpour (on a wet night it comes about every hour and a half): heavier, faster, more slanted - still falling down, still readable; it eases off smoothly.
- [ ] Drive and walk in the rain: the drops move with the street when the camera moves; the nearer drops move a little more; a zoom (getting into a car) does not throw the rain sideways.
- [ ] At a large window size or full screen the rain looks the same as at 1280 x 720 and stays with the street.
- [ ] The drops catch the light: bright under lamps, windows and headlights, faint in the dark.
- [ ] Step into a room in rain (ward, Halloran Square, the yards): no rain over the room, the street outside still wet; the rain heard dully; out again, everything as it was. The weather turning while you are inside does the same.

## The wheel
- [ ] In the gaming room the wheel is always turning: rounds go on whether or not you are at the rail. E at the rail mid-round: you join it as it stands; after "no more bets" you wait for the next.
- [ ] Put chips down while the ring runs; keep putting them down near the end: Leo waits a moment for you, then calls it anyway. "Last bets" and "No more bets" are clear (the plaque, the ring turning red, his words).
- [ ] The ball drops into the number shown on the board and in the message; you are paid once; walking away after the call pays at once; Space does nothing at the wheel.
- [ ] Mrs. Halloway, Big Stan (and later Bertie) put their own coloured chips down through the betting time (never yours, never after the call); they react to wins and losses; Leo names a big winner. The legend at the top says who is at the rail.
- [ ] Four o'clock: the round under way is played out, then the cover goes on.

## The machines
- [ ] S changes the stake (one, two or five coins) and the plate's amounts change with it.
- [ ] After a losing pull the HOLD lamps sometimes light (with a click and a soft bell). 1-3 (or a click on a reel or its latch) holds one or two reels; a third is refused; the held reels show their brass bar and stand completely still while the other spins; the stake is taken once; then the holds come off and the next pull spins all three.
- [ ] Changing the stake under lit lamps puts them out. Walking away with lamps lit and coming back: still lit.

## The card table
- [ ] The buy-in offers three stakes (left / right); the table plays them (the plaque says which); they cannot be changed while you sit.
- [ ] Esc during a hand you are still in: the question says what stays in the pot and what you take home; Esc keeps you at the table (nothing moved meanwhile), Enter folds and goes. Between hands, or after folding, you just get up.
- [ ] Chips slide into the pot and to the winner; a copper marker points at whoever is to act; the pot's last rise shows beside it; Space pacing as before.
- [ ] Quit in the middle of a hand and load: you lost what you had in the pot (a save never undoes a hand).

## The room
- [ ] Early in the evening the room is nearly empty; by midnight all five regulars are about; after three it thins; at four nobody. They come in and go out by the card room's door and walk round the furniture (no walking through tables, no circling).
- [ ] They stay at their places, turn now and then, sip, pull their machines (heard where they stand), talk to each other now and then; never in the way of your game; a regular at a machine you walk up to steps away.
- [ ] Smoke drifts under the ceiling; the lamps flicker very slightly.

## Listening checks (not done by the developer: no sound output in the development container)
- [ ] The rain bed and the downpour bed outside; dull indoors; never two rain sounds at once; no restart when going in and out.
- [ ] The wheel: Leo's bell at "place your bets" and at "no more bets", the spin as the ball is sent, the drop, the last knock into the pocket, chips, win/lose cues - in order, never piled up; quieter and from the table's side when you only watch.
- [ ] The regulars' chips (a stacking click), their machines (lever, three stops, the odd coins) placed where they are; the murmur of two talking - natural, not looping, not too loud.
- [ ] The HOLD latch thrown, the latches springing back, the lamps' relay and soft bell - mechanical, not electronic; balanced against the lever and the reels.
- [ ] The Copper Owl's song muffled through the back rooms' walls, the room's bed up inside; speech (the Bird, Rourke's greeting) ducks the room; every level follows the menu's sound settings; nothing clips.
- [ ] Any of these replaced by your own file in `custom/audio/` (see `assets/audio/README.md`) plays instead, after a restart.

## Preserved
- [ ] Everything from M001-M012 still works (driving, the economy and Rourke, the jobs, voices and the Bird's song and her last song, Lefty, the vet, incidents, Dutch and Mr. Feeney, the three districts and their streaming, the rooms in every district, the café and the emergency, the Thompson, Freight Doesn't Walk, the menu, the map and minimap, saving and loading).
- [ ] Frame rate acceptable on your machine in rain, fog, rain and fog, and in the gaming room at midnight (note it).
