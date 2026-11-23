class_name CityPlan
extends RefCounted
## The city as it is planned (M008): every district, where it lies in the one
## world and the ways between them. Plain data - building districts is the
## DistrictStreamer's job. The Riverside Ward is at the origin; its
## neighbours are drawn up in their own coordinates and placed beside it:
## the Riverfront Yards to the south (Kessler and Wharf Street run on into
## it), Halloran Square to the west (along Marlowe Avenue and Pruitt Street).
## M015: Canal Market south of the square and west of the yards (the square's
## avenues and the yards' Front and Foundry Street run on into it), and
## Lincoln Terrace north of the railroad (Wharf Street passes under it).


## Every district's layout, the Riverside Ward's (already made) first.
static func layouts(riverside: DistrictLayout) -> Array:
	var all := [riverside, RiverfrontYards.create(), HalloranSquare.create(), CanalMarket.create(), LincolnTerrace.create()]
	for l in all:
		(l as DistrictLayout).grime_items()  # M010: scattered once at start-up (data, like the map images)
		(l as DistrictLayout).ground_shadows()
		(l as DistrictLayout).fog_feet()
		(l as DistrictLayout).fog_cover()
	return all
