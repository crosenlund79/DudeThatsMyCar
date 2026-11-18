class_name OpeningScript
extends RefCounted
## The opening of a new game as data (pure): the subtitles of Danny's
## monologue and the slow drift of the camera over the Riverside Ward while
## he talks - up Marlowe Avenue from the river, past the Copper Owl's door,
## over the junction at Kessler Street and home to Danny in his flat.

## Subtitles for the shipped recording (assets/audio/voice/danny_opening.mp3,
## 23.41 s): [start s, end s, text]. Transcribed from the recording by two
## speech-recognition models that agreed word for word; times from their
## word timestamps. Shown only while that recording plays.
const CUES := [
	[0.0, 2.4, "Chicago. 1932."],
	[2.84, 5.4, "Everybody's broke. Nobody's honest."],
	[5.74, 8.9, "And somehow everybody's got money for booze."],
	[9.46, 12.2, "Name's Danny Mercer. They call me Dimes."],
	[12.58, 14.2, "I work for a fella named Rourke."],
	[14.44, 17.0, "He gets his cut. I get what's left."],
	[17.94, 20.9, "Funny thing is, there ain't usually much left."],
	[21.48, 23.4, "Well... better get to work."],
]
## The length of the recording the cues and shots were made for (s).
const RECORDING_LENGTH := 23.41
## Seconds after the voice ends before Danny is yours, and how long the
## hand-over takes (the bars slide away, the night comes back up).
const TAIL := 0.7
const OUTRO := 0.9
## The world fades up from black at the start (s).
const FADE_IN := 1.6


## The subtitle at time t ("" between lines).
static func cue_at(t: float) -> String:
	for c in CUES:
		if t >= float(c[0]) and t < float(c[1]):
			return c[2]
	return ""


## Camera keyframes for a ward [{t, pos, zoom}], spread over `length`
## seconds (the actual recording's length). `home` is where Danny stands.
static func shots(layout: DistrictLayout, club: InteriorPlan, home: Vector2, length: float) -> Array:
	var avenue_y := home.y + 200.0
	var junction_x := home.x - 800.0
	for s in layout.streets:
		if s.name == "Marlowe Avenue":
			avenue_y = (s.rect as Rect2).get_center().y
			break
	for s in layout.streets:
		if s.name == "Kessler Street":
			junction_x = (s.rect as Rect2).get_center().x
	var river_x: float = (layout.water[0] as Rect2).position.x if not layout.water.is_empty() else home.x + 1200.0
	var door := club.outside_door(0, 90.0) if club != null else home
	var keys := [
		[0.0, Vector2(river_x - 260.0, avenue_y - 40.0), 0.78],
		[0.23, Vector2(river_x - 820.0, avenue_y), 0.8],
		[0.41, door + Vector2(0.0, 30.0), 0.92],
		[0.62, Vector2(junction_x + 60.0, avenue_y + 20.0), 0.84],
		[0.84, Vector2((junction_x + home.x) * 0.5 + 250.0, avenue_y - 50.0), 0.95],
		[1.0, home, 1.2],
	]
	var out := []
	for k in keys:
		out.append({"t": float(k[0]) * length, "pos": k[1], "zoom": k[2]})
	return out


## Where the camera looks and how close at time t: a smooth curve through
## the keyframes (Catmull-Rom), holding the last one at the end.
static func rig_at(keys: Array, t: float) -> Dictionary:
	if keys.is_empty():
		return {"pos": Vector2.ZERO, "zoom": 1.0}
	if t <= float(keys[0].t):
		return {"pos": keys[0].pos, "zoom": keys[0].zoom}
	var last: Dictionary = keys[keys.size() - 1]
	if t >= float(last.t):
		return {"pos": last.pos, "zoom": last.zoom}
	var i := 0
	while i < keys.size() - 2 and t >= float(keys[i + 1].t):
		i += 1
	var a: Dictionary = keys[i]
	var b: Dictionary = keys[i + 1]
	var u := (t - float(a.t)) / maxf(float(b.t) - float(a.t), 0.001)
	var p0: Vector2 = keys[maxi(i - 1, 0)].pos
	var p3: Vector2 = keys[mini(i + 2, keys.size() - 1)].pos
	var s := u * u * (3.0 - 2.0 * u)
	return {"pos": _catmull(p0, a.pos, b.pos, p3, u), "zoom": lerpf(a.zoom, b.zoom, s)}


static func _catmull(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, u: float) -> Vector2:
	var u2 := u * u
	var u3 := u2 * u
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * u + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * u2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * u3)
