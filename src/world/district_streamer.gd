class_name DistrictStreamer
extends Node2D
## The city as neighbourhoods side by side in one world (M008, following
## docs/DISTRICT_STREAMING.md). Every district's layout - plain data, a few
## milliseconds each - is known from the start; its nodes (ground, buildings,
## lamps, street life, beat cop, parked cars) exist only while Danny is in it
## or close to one of its borders. As he comes within LOAD_DISTANCE of a
## neighbour the streamer starts building it, a few milliseconds a frame
## (BUDGET_USEC), its walking grid on a worker thread; the district appears
## (and its border opens) only when it is complete. At most MAX_LOADED are
## kept; one he has left far enough behind (UNLOAD_DISTANCE: hysteresis) is
## freed, its people's state kept for when he comes back. A district built
## elsewhere (the Riverside Ward, at start-up) can be adopted and pinned.
##
## Until a neighbour is ready, a frontier wall closes each open way into it,
## so nobody walks or drives off the edge of the loaded world.

signal district_ready(id: String)
signal district_unloading(id: String)
signal district_entered(id: String)

## Start building a neighbour when Danny is this close to its play area (px).
const LOAD_DISTANCE := 1300.0
## Free a district when he is this far from it (and it is not where he is).
const UNLOAD_DISTANCE := 1900.0
const MAX_LOADED := 2
## Work per frame while building a district (microseconds); at least one step runs.
const BUDGET_USEC := 4000
var budget_usec := BUDGET_USEC
const FRONTIER_THICKNESS := 12.0

var resolver: AssetResolver
## Every district's layout (world coordinates), by id, in plan order.
var layouts := {}
var order: Array[String] = []
## Loaded districts: id -> {layout, node, city, navigator, pinned}
var loaded := {}
## Where the focus (Danny) is.
var current := ""
## The district being built: {id, node, city, steps, next, nav_task, nav, started_usec, frames, worst_frame_usec, work_usec}
var _job := {}
## Extra steps for a district's people and cars, supplied by the game:
## func(layout: DistrictLayout, node: Node2D) -> Array[Callable].
var extra_steps: Callable
## Clearance of the walking grids (a person's radius and a little).
var clearance := 15.0
## Per-district state kept while a district is unloaded (and saved): id -> {}.
var state := {}
## Measurements: id -> {builds, last_build_usec, work_usec, frames, worst_frame_usec, worst_step_usec, unload_usec}
var stats := {}
var frontier: StaticBody2D
## Whether to stream at all (tests of a single district switch it off).
var enabled := true


func setup(p_resolver: AssetResolver, p_layouts: Array) -> void:
	name = "Districts"
	resolver = p_resolver
	for l in p_layouts:
		var layout: DistrictLayout = l
		layouts[layout.id] = layout
		order.append(layout.id)
	frontier = StaticBody2D.new()
	frontier.name = "Frontier"
	frontier.collision_layer = Layers.WORLD
	frontier.collision_mask = 0
	add_child(frontier)


## A district built elsewhere (the Riverside Ward at start-up); `pinned`: never unloaded.
func adopt(id: String, city: City, navigator: CityNavigator, pinned: bool = true) -> void:
	loaded[id] = {"layout": layouts[id], "node": city, "city": city, "navigator": navigator, "pinned": pinned, "adopted": true}
	_update_frontier()


func is_ready(id: String) -> bool:
	return loaded.has(id)


func ready_ids() -> Array[String]:
	var out: Array[String] = []
	for id in order:
		if loaded.has(id):
			out.append(id)
	return out


func is_building(id: String = "") -> bool:
	return not _job.is_empty() and (id == "" or _job.id == id)


## The district whose ground p is on ("" outside them all).
func district_at(p: Vector2) -> String:
	for id in order:
		if (layouts[id] as DistrictLayout).bounds.has_point(p):
			return id
	return ""


func layout_at(p: Vector2) -> DistrictLayout:
	var id := district_at(p)
	return layouts[id] if id != "" else null


func navigator_of(id: String) -> CityNavigator:
	return loaded[id].navigator if loaded.has(id) else null


func city_of(id: String) -> City:
	return loaded[id].city if loaded.has(id) else null


## Everything the camera may show: the loaded districts together.
func bounds() -> Rect2:
	var r := Rect2()
	var first := true
	for id in ready_ids():
		var b: Rect2 = (layouts[id] as DistrictLayout).bounds
		r = b if first else r.merge(b)
		first = false
	return r


## Open ground a person may stand on, in a loaded district (for getting out of cars).
func is_open_ground(p: Vector2, radius: float) -> bool:
	var id := district_at(p)
	return id != "" and loaded.has(id) and (layouts[id] as DistrictLayout).is_open_ground(p, radius)


## How far p is from a district's play area (0 inside it).
func distance_to(id: String, p: Vector2) -> float:
	var r: Rect2 = (layouts[id] as DistrictLayout).play_area
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dy := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dy).length()


## The districts that should be loaded with the focus at p, nearest first:
## the one he is in, then neighbours within LOAD_DISTANCE, at most MAX_LOADED
## (pinned ones always count, and stay).
func wanted(p: Vector2) -> Array[String]:
	var here := district_at(p)
	var out: Array[String] = []
	if here != "":
		out.append(here)
	for id in order:
		if loaded.has(id) and loaded[id].pinned and not out.has(id):
			out.append(id)
	var near: Array[String] = []
	for id in order:
		if not out.has(id) and distance_to(id, p) <= LOAD_DISTANCE:
			near.append(id)
	near.sort_custom(func(a: String, b: String) -> bool: return distance_to(a, p) < distance_to(b, p))
	for id in near:
		if out.size() < MAX_LOADED:
			out.append(id)
	return out


## Every frame, with Danny's position: notices which district he is in,
## frees what is far behind, starts building what is near ahead and does a
## slice of the building work.
func update(focus: Vector2) -> void:
	var here := district_at(focus)
	if here != current and here != "":
		current = here
		district_entered.emit(here)
	if not enabled:
		return
	var want := wanted(focus)
	for id in ready_ids():
		if not want.has(id) and not loaded[id].pinned and id != here and distance_to(id, focus) > UNLOAD_DISTANCE:
			unload(id)
	# room for a wanted district: let go of the loaded one he needs least
	var missing := want.filter(func(id: String) -> bool: return not loaded.has(id))
	if not missing.is_empty() and loaded.size() >= MAX_LOADED:
		var spare := ready_ids().filter(func(id: String) -> bool:
			return not want.has(id) and not loaded[id].pinned and id != here)
		spare.sort_custom(func(a: String, b: String) -> bool: return distance_to(a, focus) > distance_to(b, focus))
		if not spare.is_empty():
			unload(spare[0])
	if not _job.is_empty() and not want.has(_job.id) and distance_to(_job.id, focus) > UNLOAD_DISTANCE:
		_abandon_job()
	if _job.is_empty():
		for id in want:
			if not loaded.has(id) and loaded.size() < MAX_LOADED:
				_start(id)
				break
	if not _job.is_empty():
		_work(budget_usec)


## Builds a district straight away (loading a saved game, tests).
func load_now(id: String) -> void:
	if loaded.has(id):
		return
	if not _job.is_empty() and _job.id != id:
		_abandon_job()
	if _job.is_empty():
		_start(id)
	while not _job.is_empty():
		_work(1 << 30)


func unload(id: String) -> void:
	if not loaded.has(id) or loaded[id].get("adopted", false):
		return
	var t0 := Time.get_ticks_usec()
	district_unloading.emit(id)
	var node: Node = loaded[id].node
	loaded.erase(id)
	remove_child(node)
	node.free()
	_stat(id).unload_usec = Time.get_ticks_usec() - t0
	_update_frontier()


# ------------------------------------------------------------------ building

func _start(id: String) -> void:
	var layout: DistrictLayout = layouts[id]
	var node := Node2D.new()
	node.name = "District_" + id
	node.visible = false  # shown when complete
	add_child(node)
	var city := City.new()
	city.name = "City"
	node.add_child(city)
	var steps: Array[Callable] = city.build_steps(layout, resolver, false)
	if extra_steps.is_valid():
		steps.append_array(extra_steps.call(layout, node))
	# the walking grid is plain data: built on a worker thread meanwhile (into
	# its own holder, read only once the task is done)
	var holder := [null]
	var c := clearance
	var task := WorkerThreadPool.add_task(func() -> void: holder[0] = CityNavigator.new(layout, c))
	_job = {"id": id, "node": node, "city": city, "steps": steps, "next": 0, "nav": holder, "nav_task": task,
		"started_usec": Time.get_ticks_usec(), "frames": 0, "worst_frame_usec": 0, "worst_step_usec": 0, "work_usec": 0}


## Up to `budget` microseconds of building (at least one step).
func _work(budget: int) -> void:
	var t0 := Time.get_ticks_usec()
	var job := _job
	job.frames += 1
	while job.next < job.steps.size():
		var s0 := Time.get_ticks_usec()
		var step: Callable = job.steps[job.next]
		step.call()
		job.next += 1
		var took := Time.get_ticks_usec() - s0
		if took > job.worst_step_usec:
			job.worst_step_usec = took
			job["slowest"] = step.get_method()
		if Time.get_ticks_usec() - t0 >= budget:
			break
	if job.next >= job.steps.size():
		if not WorkerThreadPool.is_task_completed(job.nav_task) and budget < (1 << 30):
			_account(job, t0)
			return  # the grid is not quite done: next frame
		WorkerThreadPool.wait_for_task_completion(job.nav_task)
		_account(job, t0)
		_finish(job)
	else:
		_account(job, t0)


func _account(job: Dictionary, t0: int) -> void:
	var spent := Time.get_ticks_usec() - t0
	job.work_usec += spent
	job.worst_frame_usec = maxi(job.worst_frame_usec, spent)


func _finish(job: Dictionary) -> void:
	_job = {}
	var node: Node2D = job.node
	node.visible = true
	loaded[job.id] = {"layout": layouts[job.id], "node": node, "city": job.city, "navigator": (job.nav as Array)[0], "pinned": false}
	var st := _stat(job.id)
	st.builds += 1
	st.last_build_usec = Time.get_ticks_usec() - job.started_usec
	st.work_usec = job.work_usec
	st.frames = job.frames
	st.worst_frame_usec = job.worst_frame_usec
	st.worst_step_usec = job.worst_step_usec
	st.slowest_step = job.get("slowest", "")
	_update_frontier()
	district_ready.emit(job.id)


func _abandon_job() -> void:
	var job := _job
	_job = {}
	WorkerThreadPool.wait_for_task_completion(job.nav_task)
	district_unloading.emit(job.id)  # whatever the extra steps made so far is let go
	remove_child(job.node)
	(job.node as Node).free()


## Freed in the middle of building a district (a game closed, a test over):
## the walking grid's worker-thread task is waited for, never left running.
func _exit_tree() -> void:
	if not _job.is_empty():
		WorkerThreadPool.wait_for_task_completion(_job.nav_task)
		_job = {}


func _stat(id: String) -> Dictionary:
	if not stats.has(id):
		stats[id] = {"builds": 0, "last_build_usec": 0, "work_usec": 0, "frames": 0, "worst_frame_usec": 0,
			"worst_step_usec": 0, "unload_usec": 0}
	return stats[id]


# ------------------------------------------------------------------ the frontier

## A wall across every open way out of a loaded district into one that is not ready.
func _update_frontier() -> void:
	for c in frontier.get_children():
		frontier.remove_child(c)
		c.free()
	for id in ready_ids():
		for e in (layouts[id] as DistrictLayout).exits:
			if loaded.has(String(e.to)):
				continue
			var r: Rect2 = e.rect
			var shape := CollisionShape2D.new()
			var box := RectangleShape2D.new()
			box.size = Vector2(maxf(r.size.x, FRONTIER_THICKNESS), maxf(r.size.y, FRONTIER_THICKNESS))
			shape.shape = box
			shape.position = r.get_center()
			frontier.add_child(shape)


## The frontier walls standing now (for tests and the map).
func frontier_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c in frontier.get_children():
		var shape := c as CollisionShape2D
		var size: Vector2 = (shape.shape as RectangleShape2D).size
		out.append(Rect2(shape.position - size * 0.5, size))
	return out


# ------------------------------------------------------------------ per frame

## The neighbours' perspective (the adopted district is the game's to update).
func update_view(eye: Vector2, eye_height: float, view: Rect2) -> void:
	for id in loaded:
		if not loaded[id].get("adopted", false):
			(loaded[id].city as City).update_view(eye, eye_height, view)
