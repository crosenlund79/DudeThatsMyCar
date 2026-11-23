# Golden master: re-recordings in M015

The snapshots in this folder started as copies of `tests/golden/m013/` (recorded on the M013 code,
reproduced exactly by M014). M015 changes the game on purpose; a case is recorded again here only after
its differences against the previous recording were read and found to be exactly the intended change.

| Stage | Cases | Why they differ |
| --- | --- | --- |
| M015.1 roulette pace and limits | `wheel_paid`, `machines_played`, `poker_three_hands`, `poker_left` (`test_the_house_books`) | Leo's rounds are quicker at the Normal pace (5 + 5 s of bets, the number 4 s: M013's 9 + 7 s and 5.5 s are now Relaxed), so the course reaches each checkpoint about 13.5 game minutes earlier; what follows the clock moves with it (the club's till and stock, the night's share of the ward's day, the weather, an incident not yet over, the round under way at the wheel). Danny's money at the wheel is the same. |
| M015.2 the approved hold rule | `machines_played`, `poker_three_hands`, `poker_left` (`test_the_house_books`) | The HOLD lamps now light after every losing full pull (M013: one in three or four) and the paytables were rebalanced (the Owl's top prize 30 coins, was 40, and so on), so the course - which holds reel 1 whenever the lamps are lit - makes more hold-assisted pulls, ends with different reels, money ($47.25, was $48.45) and a later minute; the poker that follows inherits the money and the clock. `wheel_paid` is unchanged. |
| M015.3 poker time | `poker_three_hands`, `poker_left` (`test_the_house_books`) | While Danny plays at the card table the night runs at a quarter of its pace and stands still while a beat waits for Space, so the three hands end about 2.7 game minutes earlier on the clock (and the club's till and the night's share follow); the cards, chips and money are the same. |
| M015.4 cars kept through sleep; Lefty's car | every case (and `layouts.json`) | Lefty Moran's speedster is a new parked car of the ward (`riverside/9`, at the kerb by his corner): it appears in every snapshot's car list and in the ward's layout (the fingerprint's only eight differences are that car), and the books carry a new `lefty_car` record. With that car and that record set aside, every snapshot is identical to the previous recording (`/tmp` comparison script; none of the courses leaves a car elsewhere at dawn). |

Recordings are always made by running the whole golden script in its usual order (`GOLDEN_RECORD=1`, no test filter): a case run on its own is the first in its process, and the very first scene in a Godot process gets one frame of the night clock less (see `test_new_game_and_the_opening`).
