"""M013: the exact odds of the gaming room's machines with hold-and-respin.

    python3 tools/slot_odds/analyse.py [src/gaming/slot_owl.tres ...]

Reads each machine's reel strips and paytable from its .tres and works out,
exactly (every combination of stops, no sampling):

  * the return of plain pulls (every pull a full spin);
  * after a losing full spin the HOLD lamps light with the machine's
    hold_chance (a fair draw with the pull); then the player may hold one or two reels (never three)
    for the next pull at the same stake; held reels keep their stop, the
    others are drawn afresh; after that respin the next pull must be a full
    spin again. The best a player can do: hold whenever (and whatever) gives
    the most, if that is worth more than a fresh full spin. Over the long run
    this is a cycle - a full spin, sometimes followed by one respin - so the
    return is (what a full spin pays + what the respins pay) / (coins put in),
    maximised over the threshold policy "respin when a hold is worth v or more"
    (a lit lamp comes with hold_chance of the losing full spins).

The same sums are done in GDScript by SlotMachine (expected_return,
best_hold_return), and test_slot_machine checks they agree with the numbers
printed here."""
import itertools, re, sys

def parse(path):
    text = open(path).read()
    strips = [s.split(", ") for s in re.findall(r'PackedStringArray\(([^)]*)\)', text)]
    strips = [[x.strip().strip('"') for x in s] for s in strips]
    pays = []
    for m in re.finditer(r'\{"coins": (\d+), "line": \[([^\]]*)\]\}', text):
        pays.append((int(m.group(1)), [x.strip().strip('"') for x in m.group(2).split(",")]))
    title = re.search(r'title = "([^"]*)"', text).group(1)
    q = re.search(r'hold_chance = ([0-9.]+)', text)
    return title, strips, pays, float(q.group(1)) if q else 1.0 / 3.0

def coins(pays, line):
    for c, want in pays:
        if all(w == "*" or w == s for w, s in zip(want, line)):
            return c
    return 0

def analyse(path):
    title, strips, pays, q = parse(path)
    n = [len(s) for s in strips]
    total = n[0] * n[1] * n[2]
    base = sum(coins(pays, (a, b, c)) for a in strips[0] for b in strips[1] for c in strips[2]) / total
    # what holding reels `held` (at stops `at`) is worth on the respin (coins, mean)
    cache = {}
    def held_value(held, at):
        key = (held, tuple(at[r] for r in held))
        if key in cache:
            return cache[key]
        free = [r for r in range(3) if r not in held]
        s = 0
        cnt = 0
        for picks in itertools.product(*[range(n[r]) for r in free]):
            st = list(at)
            for r, p in zip(free, picks):
                st[r] = p
            s += coins(pays, [strips[r][st[r]] for r in range(3)])
            cnt += 1
        cache[key] = s / cnt
        return cache[key]
    holds = [(0,), (1,), (2,), (0, 1), (0, 2), (1, 2)]
    best = []  # for each losing full-spin outcome: the best hold's value
    for at in itertools.product(range(n[0]), range(n[1]), range(n[2])):
        line = [strips[r][at[r]] for r in range(3)]
        if coins(pays, line) > 0:
            continue
        best.append(max(held_value(h, at) for h in holds))
    loss_p = len(best) / total
    # the threshold policy maximising the long-run return
    vals = sorted(best, reverse=True)
    best_r, best_k = base, 0
    s = 0.0
    for k, v in enumerate(vals, 1):
        s += v
        r = (base + q * s / total) / (1 + q * k / total)
        if r > best_r:
            best_r, best_k = r, k
    threshold = vals[best_k - 1] if best_k else None
    return title, base, best_r, loss_p, q * best_k / total, threshold, q

if __name__ == "__main__":
    paths = sys.argv[1:] or ["src/gaming/slot_owl.tres", "src/gaming/slot_bell.tres", "src/gaming/slot_star.tres"]
    for p in paths:
        title, base, held, loss, respin, thr, q = analyse(p)
        print("%-9s plain pulls %6.2f%%   with the best holds %6.2f%%   (HOLD lamps after 1 in %.0f losing pulls; loses %4.1f%% of full pulls; a respin after %4.1f%% of them at best%s)" % (
            title, base * 100, held * 100, 1.0 / q, loss * 100, respin * 100, ", holds worth %.2f coins and up" % thr if thr else ""))
