#!/usr/bin/env bash
# Chicago, 1932 - test tiers (M014). Run from anywhere; needs `godot` (4.7) on PATH
# (or GODOT=/path/to/godot). See tests/README.md for when to run which tier.
#
#   tools/test.sh unit                 every unit test (pure modules), one process
#   tools/test.sh integration          every integration test (the real scene), in parallel
#   tools/test.sh full                 every test script, in parallel (the regression suite)
#   tools/test.sh serial               every test script in one process, as before M014
#   tools/test.sh playthrough          the multi-night playthroughs, in parallel
#   tools/test.sh golden               the M013 golden-master snapshots
#   tools/test.sh only <name>...       test scripts whose file names contain any <name>
#
# Options (before the tier): -j N  parallel workers (default: CPU count, at most 4)
#                            -k    keep the per-script logs (in $TEST_LOGS or a temp dir)
# Parallel runs give each script its own Godot process and its own user:// folder,
# check that every test script was found and ran, and fail on any failing test,
# a script that did not parse (GUT skips those silently) or a crashed process.

set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
JOBS=$(nproc 2>/dev/null || echo 2)
[ "$JOBS" -gt 4 ] && JOBS=4
KEEP=0
while [ $# -gt 0 ]; do
	case "$1" in
		-j) JOBS="$2"; shift 2 ;;
		-k) KEEP=1; shift ;;
		*) break ;;
	esac
done
TIER="${1:-}"
[ $# -gt 0 ] && shift

PLAYTHROUGHS="test_a_nights_work test_the_city_has_ears test_dangerous_company test_a_job_for_rourke \
test_beyond_riverside_ward test_the_city_doesnt_sleep test_the_darker_side test_power_and_vice \
test_city_behind_closed_doors test_the_house_always_wins test_the_city_breathes"

all_scripts() { find tests/unit tests/integration -name 'test_*.gd' | sort; }

strip() { sed 's/\x1b\[[0-9;]*m//g'; }

# One process for a whole directory set (the GUT config as it is).
serial() {
	local log; log=$(mktemp)
	local start=$SECONDS
	"$GODOT" --headless --path . --fixed-fps 60 -s addons/gut/gut_cmdln.gd "$@" > "$log" 2>&1
	local code=$?
	strip < "$log" | awk '/= Run Summary/{f=1} f' | grep -E '^res://|^- test|Failed|at line|Scripts|Tests |Passing|Failing|Risky|Pending|All tests' | head -120
	local want got
	got=$(strip < "$log" | grep -E '^Scripts' | grep -oE '[0-9]+' | head -1)
	echo "($((SECONDS - start)) s)"
	# the whole log is kept when anything failed (or with -k), for the details
	if [ "$KEEP" = 1 ] || [ "$code" != 0 ]; then echo "log: $log"; else rm -f "$log"; fi
	echo "$got"
	return "$code"
}

# Each script in its own process, JOBS at a time; heaviest (largest) first.
parallel() {
	local files=("$@")
	local n=${#files[@]}
	[ "$n" -gt 0 ] || { echo "no test scripts matched"; return 1; }
	local dir="${TEST_LOGS:-$(mktemp -d)}"
	mkdir -p "$dir"
	local start=$SECONDS
	# slowest first, by the last run's times on this machine (.godot/test_timings.txt, a cache;
	# a script never timed counts as slow), so the workers finish together
	local timings=".godot/test_timings.txt"
	for f in "${files[@]}"; do
		local t; t=$(grep -F " $f" "$timings" 2>/dev/null | tail -1 | cut -d' ' -f1)
		echo "${t:-9999} $f"
	done | sort -rn | cut -d' ' -f2 \
		| xargs -P "$JOBS" -I{} sh -c '
			f="{}"; base=$(echo "${f%.gd}" | tr / _); home=$(mktemp -d)
			t0=$(date +%s)
			XDG_DATA_HOME="$home" timeout 1500 "$0" --headless --path . --fixed-fps 60 -s addons/gut/gut_cmdln.gd \
				-gconfig= -gtest="res://$f" -gexit -glog=1 > "$1/$base.log" 2>&1
			echo "exit=$? seconds=$(( $(date +%s) - t0 ))" >> "$1/$base.log"
			rm -rf "$home"' "$GODOT" "$dir"
	local scripts=0 tests=0 passing=0 bad=0
	for f in "${files[@]}"; do
		local log="$dir/$(echo "${f%.gd}" | tr / _).log"
		local s t p code secs
		s=$(strip < "$log" | grep -E '^Scripts' | grep -oE '[0-9]+' | head -1)
		t=$(strip < "$log" | grep -E '^Tests ' | grep -oE '[0-9]+' | head -1)
		p=$(strip < "$log" | grep -E '^Passing Tests' | grep -oE '[0-9]+' | head -1)
		code=$(grep -oE 'exit=[0-9]+' "$log" | tail -1 | cut -d= -f2)
		secs=$(grep -oE 'seconds=[0-9]+' "$log" | tail -1 | cut -d= -f2)
		s=${s:-0}; t=${t:-0}; p=${p:-0}
		scripts=$((scripts + s)); tests=$((tests + t)); passing=$((passing + p))
		if [ "$s" != 1 ] || [ "$code" != 0 ] || [ "$t" != "$p" ] || [ "$t" = 0 ]; then
			bad=$((bad + 1))
			echo "FAILED $f (scripts $s, tests $t, passing $p, exit $code, ${secs}s)"
			strip < "$log" | awk '/= Run Summary/{f=1} f' | grep -E '^- test|Failed|at line|SCRIPT ERROR|Parse Error' | head -20
			strip < "$log" | grep -E 'SCRIPT ERROR|Parse Error|ERROR:' | head -5
		fi
	done
	mkdir -p .godot
	for f in "${files[@]}"; do
		local secs; secs=$(grep -oE 'seconds=[0-9]+' "$dir/$(echo "${f%.gd}" | tr / _).log" | tail -1 | cut -d= -f2)
		[ -n "$secs" ] && { grep -vF " $f" "$timings" 2>/dev/null; echo "$secs $f"; } > "$timings.new" && mv "$timings.new" "$timings"
	done
	echo "Scripts $scripts of $n   Tests $tests   Passing $passing   Failing scripts $bad   ($((SECONDS - start)) s, $JOBS workers)"
	[ "$KEEP" = 1 ] && echo "logs: $dir" || { [ -z "${TEST_LOGS:-}" ] && rm -rf "$dir"; }
	[ "$bad" = 0 ] && [ "$scripts" = "$n" ]
}

case "$TIER" in
	unit)
		mapfile -t F < <(find tests/unit -name 'test_*.gd' | sort)
		parallel "${F[@]}" ;;
	integration)
		mapfile -t F < <(find tests/integration -name 'test_*.gd' | sort)
		parallel "${F[@]}" ;;
	full)
		mapfile -t F < <(all_scripts)
		parallel "${F[@]}" ;;
	serial)
		want=$(all_scripts | wc -l)
		out=$(mktemp)
		serial > "$out"; code=$?
		cat "$out"; got=$(tail -1 "$out"); rm -f "$out"
		[ "$got" = "$want" ] || { echo "only $got of $want test scripts ran"; exit 1; }
		[ "$code" = 0 ] || { echo "failing tests (see above)"; exit 1; } ;;
	playthrough)
		F=()
		for p in $PLAYTHROUGHS; do F+=("tests/integration/$p.gd"); done
		parallel "${F[@]}" ;;
	golden)
		parallel tests/integration/test_golden_master.gd ;;
	only)
		[ $# -gt 0 ] || { echo "usage: tools/test.sh only <name>..."; exit 2; }
		F=()
		while read -r f; do
			for pat in "$@"; do
				case "$(basename "$f")" in *"$pat"*) F+=("$f"); break ;; esac
			done
		done < <(all_scripts)
		parallel "${F[@]}" ;;
	*)
		sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
		exit 2 ;;
esac
