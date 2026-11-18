# Manual playtest checklist — Milestone 005: The City Has Ears

Play `src/main/main.tscn` with keyboard and mouse, **with headphones** for the listening checks. Tick each item; note problems in `docs/BACKLOG.md` (not as tasks).

The automated tests check levels, filters, routing, timing and continuity in a headless run with no sound card. They cannot tell how anything *sounds*: every item under "Listening" needs a person. Nothing here has been checked by ear yet.

## Starting a new game
- [ ] Delete `user://chicago1932_save.json` (see the README) and start: the screen fades up from black over the ward at night, black bars above and below, Danny's voice from the first word.
- [ ] Subtitles appear in step with his words, one line at a time, and match what he says.
- [ ] The camera drifts slowly from the river, past the Copper Owl (its sign, the canopy), over a junction, to Danny in his flat; people, cars and the beat cop are already about.
- [ ] At "Well... better get to work." the bars slide away, the HUD and the minimap appear, and Danny moves at once; nothing jumps.
- [ ] Start again (delete the save) and press E (then Space, Enter, Esc, a click) during the monologue: it fades out quickly and hands over the same way. Esc does not open the pause screen.
- [ ] Quit and start again: no monologue (the game was saved when it ended). Sleeping into the next evening never plays it.

## Listening — the opening
- [ ] Danny's voice is clear, natural and at a comfortable level; it is not filtered, echoed or cut short.
- [ ] Under it the night is quiet but present (street, the singer muffled as the camera passes the club); nothing competes with his voice.
- [ ] After the hand-over the night comes back up smoothly, without a jump in level.

## Listening — the Copper Owl
- [ ] Standing in the flat at the start: the singer is faint and dull through the wall.
- [ ] Out on Marlowe Avenue a block away: the music is muffled — the bass and the beat carry, the voice is a murmur — and comes from the club's side (left / right in the headphones).
- [ ] Walking to the door it grows louder and a little brighter, gradually, with no steps or pumping.
- [ ] Through the door it opens up over about a second into the full recording: warm, rich, stereo, the vocals clearly audible, the room's chatter and glasses under it but never over the singer.
- [ ] The song does not restart, skip, stutter or double when you go in or out; walking in and out several times, it simply carries on.
- [ ] Leaving, it closes back to the muffled sound and fades as you walk away.
- [ ] Driving away in a car it sinks under the engine and the street within a block or so.
- [ ] Wait for the song to end (about 4 minutes 14 seconds): it fades out with its final chord, a short breath of silence, and starts again — no click, no burst of noise, no long gap. (The original recording's stray noise at the very end must never be heard.)
- [ ] Leave the game paused for a while and resume: the song carries on where it was.

## Listening — the night
- [ ] Marlowe Avenue in the evening: a soft bed of distant traffic, not a loop you notice; now and then a horn a few streets away, never repeatedly in quick succession.
- [ ] After 2 am (sleep a night or play on): the street is noticeably quieter, horns rarer.
- [ ] In a back alley: the street recedes, water drips with a little echo off the brick; sometimes a lid clatters somewhere down it.
- [ ] By the river at the end of Marlowe Avenue: water against the quay, a low factory drone, now and then a tug's whistle out on the water.
- [ ] Inside a shop or the flat the street comes through dull, as through windows.
- [ ] A passing car's engine is heard as it goes by and fades.
- [ ] The loops (street, alley, river, the club's crowd) never click or jump when they come round.
- [ ] Doors: a latch, a creak and the door falling to; the shops' bells (Sal's, Novak's, Lindqvist's) but not the club's or the flat's; the till when money changes hands at Sal's, Augie's and Novak's; bottles clinking when rye changes hands; a heavy car door getting in and out.
- [ ] Nothing distorts or clips, even shooting inside the Copper Owl while the band plays.

## Sound levels
- [ ] Esc: the pause screen lists Master, Music, Engine, Effects, Voice and Ambience with their levels. Up / Down choose one, Left / Right change it by a tenth, heard at once (resume to hear the world change).
- [ ] Turn Ambience down: the street, alley, river and crowd go quieter, the music does not. Music down: the singer quieter, the rest not.
- [ ] Quit and start: the levels are as you left them.

## The ward's business
- [ ] Sal's price changes with what is in his cupboard; after a couple of good deals he knocks a dime off.
- [ ] Sell rye at the Copper Owl several nights running: Augie pays less when his cellar is full and buys only what it has room for and his till can pay; on a night you bring none, his cellar runs dry and the next night he pays more.
- [ ] Collect from Novak several nights running (lean on him sometimes): his till runs short, the truck brings less, the shelves look bare in what he says; offer to lend him the money for the truck, and see him repay it with a quarter on top over the next nights.
- [ ] Rourke at his corner table: the HUD shows how much of your money is his. Hand it all over (he warms, pays your end); tell him it was a thin night when it was not (he may accept it — until the talk reaches him); keep some back; ask for time and then fail to pay. Over several nights: his mood turns, your end shrinks, Augie stops buying your rye, his boys collect in the morning; pay him in full and things settle.
- [ ] Ask Sal, Augie and Rourke for news: what they say follows what has happened (a short delivery, a threat, a favour) a night or two later.
- [ ] None of it ever ends the game; there is always a way to square things.

## Still as before
- [ ] Driving, shooting, the beat cop, the five rooms with their roofs opening, the markers and the minimap all work as in M004.
