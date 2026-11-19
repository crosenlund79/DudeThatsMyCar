# Poker taunts - recording draft (M013)

A draft for a recording session: the card players' lines at the Copper Owl's back-room table, by situation. **Nothing here is recorded or synthesised, and nothing is said in the game until a recording exists.** The words and delivery notes are a performance script for whoever records them; the notes are never shown in the game.

- **How a recording is used:** save it as `custom/audio/voice/poker/<id>.ogg` (or `.wav` / `.mp3`) next to the game (or ship it under `assets/audio/voice/poker/`). The game plays a card player's line now and then (about one situation in three), only if that line's recording is there, never over another voice. Missing recordings are simply silent.
- **Where the hook is:** `PokerTaunts` (`src/poker/poker_taunts.gd`) holds the lines below and reads what a shown beat means (`situations`); `main._poker_taunt` picks a line on each beat that comes on show (`PokerView.beat_shown`). Adding a line means adding it there and here.
- **Length:** short - one breath, under three seconds; the table's pace is one beat per Space press.
- **Situations:** `fold` - folding; `raise` - betting or raising with a real hand; `bluff` - betting or raising with nothing made (he knows; the table doesn't); `win` - taking a pot; `lose` - losing at the showdown; `complain` - losing a big pot at the showdown (twenty big blinds or more); `at_danny` - Danny takes a pot off him.

## Irv Feldman (`irv`) - a bookkeeper who counts every chip (careful)

| Line id (file name) | Situation | Words | Delivery |
|---|---|---|---|
| `irv_fold_1` | fold | "Too rich for a careful man." | dry, closing his cards with one finger |
| `irv_raise_1` | raise | "I'll make it a little dearer." | quiet, almost apologetic |
| `irv_bluff_1` | bluff | "Numbers don't lie. Mostly." | a thin smile, not looking up |
| `irv_win_1` | win | "Into the ledger it goes." | satisfied, stacking chips neatly |
| `irv_lose_1` | lose | "Hm. A rounding error." | pained, under his breath |
| `irv_complain_1` | complain | "The odds on that were eleven to one. Eleven!" | aggrieved, tapping the table |
| `irv_danny_1` | at_danny | "You play loose for a man in your line, Mercer." | polite, wary |

## Red Gallagher (`red`) - a longshoreman who bets like he's throwing a punch (pushy)

| Line id (file name) | Situation | Words | Delivery |
|---|---|---|---|
| `red_fold_1` | fold | "Bah. Take it." | gruff, tossing the cards |
| `red_raise_1` | raise | "Raise. Let's see some spine." | loud, leaning over the table |
| `red_raise_2` | raise | "That's my money talking." | a growl, chips slapped down |
| `red_bluff_1` | bluff | "Go on. Call me. I dare ya." | too loud, grinning |
| `red_win_1` | win | "Come to papa!" | a bark of a laugh, raking the pot |
| `red_lose_1` | lose | "Lousy cards all night." | sour, low |
| `red_complain_1` | complain | "On the river? Somebody's dealing from the bottom!" | furious, half out of his chair |
| `red_danny_1` | at_danny | "Rourke pay you to rob honest workingmen too?" | needling, half a joke |

## Lucky Pete (`pete`) - a trolley conductor who never met a hand he didn't like (loose)

| Line id (file name) | Situation | Words | Delivery |
|---|---|---|---|
| `pete_fold_1` | fold | "Next stop, the next hand!" | cheerful, a conductor's call |
| `pete_raise_1` | raise | "All aboard - raise!" | sing-song |
| `pete_bluff_1` | bluff | "I got a feeling about this one." | breezy, winking at nobody |
| `pete_win_1` | win | "Lucky Pete rides again!" | delighted, slapping the felt |
| `pete_lose_1` | lose | "Easy come, easy go." | shrugging, unbothered |
| `pete_complain_1` | complain | "Aw, that's a crime, that is." | mock-wounded |
| `pete_danny_1` | at_danny | "Mercer, you're a regular card shark!" | admiring, friendly |

## Moe Brandt (`moe`) - a cutter from the garment trade, in late off the streetcar (careful)

| Line id (file name) | Situation | Words | Delivery |
|---|---|---|---|
| `moe_fold_1` | fold | "Not with these, no." | tired, off the late streetcar |
| `moe_raise_1` | raise | "So, a little more." | measured, a tailor's precision |
| `moe_bluff_1` | bluff | "Who knows? Maybe I have it." | deadpan, eyebrows up |
| `moe_win_1` | win | "A good night after all." | quietly pleased |
| `moe_lose_1` | lose | "Such is life." | resigned |
| `moe_complain_1` | complain | "I should have stayed on the streetcar." | rueful, shaking his head |
| `moe_danny_1` | at_danny | "You I should have watched closer." | dry respect |
