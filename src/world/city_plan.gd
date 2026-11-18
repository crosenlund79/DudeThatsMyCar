class_name CityPlan
extends RefCounted
## The city as it is planned (M008): every district, where it lies in the one
## world and the ways between them. Plain data - building districts is the
## DistrictStreamer's job. The Riverside Ward is at the origin; its
## neighbours are drawn up in their own coordinates and placed beside it:
## the Riverfront Yards to the south (Kessler and Wharf Street run on into
## it), Halloran Square to the west (along Marlowe Avenue and Pruitt Street).


## Every district's layout, the Riverside Ward's (already made) first.
static func layouts(riverside: DistrictLayout) -> Array:
	return [riverside, RiverfrontYards.create(), HalloranSquare.create()]
