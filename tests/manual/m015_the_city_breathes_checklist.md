# Manual playtest checklist - Milestone 015: The City Breathes

Play `src/main/main.tscn` with keyboard, mouse and headphones, ideally on a real graphics card and at your usual window size (full screen too), over two or three nights - one of them wet and one foggy. Tick each item; note problems in `docs/BACKLOG.md` (not as tasks). The developer tools (Esc, Developer tools; switch them on there) can take you to any district, place or room, set the time and the weather, and give money.

## The tables (M015.1-3)
- [ ] Roulette: T changes the betting timer (Quick, Normal, Relaxed) from Leo's next round; it is remembered after a restart. Leo still waits a moment after your last chip. The higher limits are printed under the chips; a $5 chip on a number pays 35 to 1 exactly.
- [ ] The regulars' coloured chips go down through the betting time; Leo calls their bets; watching from the room is worth it.
- [ ] Slots: after a pull that pays nothing the HOLD lamps light; hold one or two reels, pull: only the others spin; the next pull spins all three (never two holds in a row). Stake changes and walking away behave as before.
- [ ] Poker: the clock crawls while you sit in and stops while a step waits for Space (the game still breaks up at four). New board cards are framed in gold until you press Space. At a showdown every hand still in is turned up with its name; the winner's five cards are framed in gold, a loser's best five with a pale line; a split pot is clear. Folded hands are never shown.

## Developer tools (M015.5)
- [ ] Esc, Developer tools: switch them on; every group works (money, time and the next night, weather, districts, places and rooms, cars, health and ammunition, the police, jobs started over, films, the tables, people's memories). Anything that throws something away asks first. Save and load after using them: the game is consistent.

## People and the gun (M015.6-7, M015.10)
- [ ] Walk the pavements with your gun drawn (H): passers-by edge away and run if you come close; shopkeepers won't serve you until you put it away; a copper tells you to put it away and comes for you if you don't (sooner with the Thompson); Lefty warns you. Holster it: things settle.
- [ ] Drive at people: they see you coming, step off your line towards the kerb, throw themselves clear; chasing one down is hard. A clip, a hard knock and worse look and feel different; a copper who saw it comes for you; people you know remember.
- [ ] The streets have their regulars at their hours (the newsboy early, the Owl's crowd from nine, couples, drunks after eleven, the Bijou's late crowd, dockers at Dutch's...), a word over a head now and then - never a crowd. The Owl's van at half past nine, Kowalski's before dawn, cabs among the traffic. Each beat cop's mood shows in a word as you pass.

## Cars (M015.4)
- [ ] Leave your sedan anywhere (in another district too) and sleep: the next evening it is where you left it. A car you took stays taken; getting back in is no new theft.
- [ ] Lefty's black speedster at his kerb: take it in front of him (he goes for his gun), or unseen (he misses it the next evening). Return it.

## Work marks and the Notebook (M015.8)
- [ ] Esc, Notebook: case sheets - things, persons, places, where it stands, what you know, what you don't, leads; Left / Right leafs, Up / Down scrolls, Enter switches the street marks off and on. Settled business stays as closed cases.
- [ ] Known work: a small brass lozenge by the door or the person, the name as you come close; a chevron at the screen's edge when it is out of sight; on the minimap and as a copper ring on the city map. Suspected work: a pale hollow mark, a dashed ring, no chevron. Nothing for work you know nothing of.

## Emergency vehicles (M015.9)
- [ ] After the café job's blast (or with the developer tools), the ambulance and the fire engine look like convincing 1932 vehicles in the hand-painted style, front and back clear at every heading, their lamps where the lights come from.

## The new quarters (M015.11)
- [ ] Drive south down Halloran Avenue (or Garrity, Ashby) from the square into **Canal Market**: no stop, no jump; "CANAL MARKET" on the HUD. The El runs the length of Market Street on its columns; now and then its lit train crosses overhead, rumbling (louder near it), and stands at the terminal by Ashby Street. Drive under it: the columns stand at the kerb and the middle line, never in a lane.
- [ ] From the market, drive east along Front or Foundry Street into the yards. Walk the market: St. Casimir's and its plaza and fountain, the hall's glass roof, the Golden Lantern's lanterns, Feld's three balls, the baths, shut stalls and pushcarts, the barges on the canal.
- [ ] From the ward, drive north up Wharf Street under the railroad bridge into **Lincoln Terrace**: the Belvedere's eleven storeys and lit canopy, the Paradise's dome and marquee on Lake Street, the old water tower in its plaza, the mansions behind their gates and gardens (try a gate), the Calumet Club, the Silver Slipper, Chez Antoine, the library, the river promenade (sit on a bench). It should feel rich, bright and clean next to the market's grime.
- [ ] M: the city map shows five districts in their true places, the underpass and the El terminal labelled, the new places' badges; drag, zoom, R recentres. The minimap follows you across every border.
- [ ] Each new district has its own beat cop, parked cars, traffic and cabs, regulars, and incidents now and then.

## The landmark rooms (M015.12)
- [ ] Badges over the doors of the Canal Market Hall (basket), the Golden Lantern (bowl), Feld's (three balls), the Belvedere (key) and the Paradise (notes), brighter as you come near; on the minimap and the city map. No lamp post or stall in front of a door.
- [ ] Every room: walk in, the roof lifts, people at their places, E talks to each; walls and furniture hold; E at the door takes you out. The market hall's back door opens on Foundry Street.
- [ ] Mrs. Dvorak: coffee a nickel, twice a night; late at night (after half past three) the heaviness backs off for an hour or so. Henry Chu: a plate for a quarter, and the talk at his tables (about you, once there is some). Abe Feld: one box of .45s a night at $3.75, refused when your pockets are full. Ellery Pratt: a dollar under the blotter buys word of who is upstairs. Ruby: a dime a dance (four minutes pass), three a night. The bandleader plays your tune for a nickel - the band's pace changes.
- [ ] Listening (headphones): the Paradise's band is heard from Lake Street, muffled and quieter; it opens up as you step inside and closes down as you step out, without restarting; it stops at three. The market hall has the odd cleaver and cup, the Lantern cups and glasses, the Paradise glasses and laughter. The El's rumble rises and falls as the train passes. Nothing clips; the sound levels in the menu work for all of it.
- [ ] With your gun drawn, every keeper asks you to put it away first.
- [ ] Save in any of the rooms, load: you are there, the night's dealings (coffees, dances, the tune) kept.

## The quarters' business (M015.13)
- [ ] Read the market's noticeboard (or ask Hrabal who runs things): "Stall insurance" appears in the Notebook as a lead with a faint mark at the Lantern. Ask Henry Chu who "K." is: Kaz Wrobel is named, a sure mark on his corner table (eleven to two only).
- [ ] Settle it each way over a few games: beat Kaz in a fistfight (lose once first: you are bruised and can try again), buy him off for $5, or get in on it (a dollar a night at the Lantern; Hrabal turns cold). Hrabal thanks you once from the stallholders' tin when Kaz is gone; never for a cut.
- [ ] From the second night a dollar for Pratt tells of a State's Attorney's man asking about Rourke's people: tell Rourke (he is pleased) or keep quiet (after two nights the case lapses).
- [ ] After a tune, the bandleader asks you to take the Bird his card (and pays a dollar): give it to her (she keeps it), or to Rourke (the bandleader resents it), or let it lapse.
- [ ] None of it is a mission board: nothing is offered until you have heard of it; the Notebook only says what you know.

## Everything else still works
- [ ] A full night in the ward as before: the rye trade, protection, Rourke, the Bird, Lefty, the vet, the incidents, the weather (rain, fog indoors and out), the café job, Freight Doesn't Walk, the Bird's last song, the tables, sleeping, the opening of a new game, the six sound levels.
- [ ] Performance on your machine: crossing into each district, three districts built (in the market near the square, or in the terrace near the ward), fog over the market, the Paradise with its band. Note the frame rate and any hitch.
