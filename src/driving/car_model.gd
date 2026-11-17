class_name CarModel
extends RefCounted
## Pure, deterministic top-down driving model (no scene dependencies), carried
## over from HyperCars. Heading 0 points along +X. Steering rotates the car;
## velocity keeps its momentum and is pulled towards the heading by grip, which
## produces sliding. City driving adds a brake / reverse pedal, a handbrake and
## speed-dependent steering (see DrivingParams).

## Below this forward speed (px/s) the car counts as stopped for gear changes.
const STOP_SPEED := 1.0

var params: DrivingParams
var position := Vector2.ZERO
var heading := 0.0
var velocity := Vector2.ZERO
## Extra rotation (rad/s) from being struck by another car; fades quickly.
var yaw_rate := 0.0
## Where the steering wheel is (-1 full left .. +1 full right); follows the
## driver's command at the rates in DrivingParams.
var steer_level := 0.0
## How hard the engine pulls (0 idle .. 1 full); follows W / reverse.
var drive_level := 0.0
## How hard the brakes bite (0 .. 1); builds at brake_rise_time.
var brake_level := 0.0
## Sideways sliding speed the tyres have not caught (px/s): 0 in clean
## driving, large in a handbrake slide or after a knock (tyre squeal).
var slip := 0.0


func _init(p_params: DrivingParams = null) -> void:
	params = p_params if p_params != null else DrivingParams.new()


func forward() -> Vector2:
	return Vector2.from_angle(heading)


func forward_speed() -> float:
	return velocity.dot(forward())


func lateral_speed() -> float:
	return velocity.dot(forward().orthogonal())


## Share of the full turn rate available at a forward speed: none at rest;
## at low speed the car follows its tightest circle (min_turn_radius) or, in
## the M001 setting, fades in linearly to full_steer_speed; a little less at
## top speed; negative while rolling backwards (the car turns the other way,
## as a real car reversing does).
func steer_factor(fwd_speed: float) -> float:
	var a := absf(fwd_speed)
	var f := 1.0
	var full := 0.0  # speed from which the full turn rate is available
	if params.min_turn_radius > 0.0:
		full = params.min_turn_radius * deg_to_rad(params.turn_rate_degrees)
	elif params.full_steer_speed > 0.0:
		full = params.full_steer_speed
	if full > 0.0:
		f = clampf(a / full, 0.0, 1.0)
	if params.high_speed_turn_scale < 1.0 and params.max_speed > full:
		var r := clampf((a - full) / (params.max_speed - full), 0.0, 1.0)
		f *= lerpf(1.0, params.high_speed_turn_scale, r * r)
	return -f if fwd_speed < -STOP_SPEED else f


## Pull at a forward speed with the engine at full: fades towards top speed.
func pull_at(fwd_speed: float, base: float, top: float) -> float:
	if params.accel_falloff <= 0.0 or top <= 0.0:
		return base
	var r := clampf(absf(fwd_speed) / top, 0.0, 1.0)
	return base * (1.0 - params.accel_falloff * r * r)


## Moves the wheel towards the driver's command: turning in takes
## steer_rise_time, straightening (or swinging across) steer_return_time.
func _turn_wheel(delta: float, command: float) -> void:
	var target := clampf(command, -1.0, 1.0)
	var returning := absf(target) < absf(steer_level) or (steer_level != 0.0 and signf(target) != signf(steer_level))
	var time := params.steer_return_time if returning else params.steer_rise_time
	if time <= 0.0:
		steer_level = target
	else:
		steer_level = move_toward(steer_level, target, delta / time)


## Yaw rate (rad/s) of a road car (wheelbase > 0) rolling at fwd_speed with
## the wheel at `level`: it follows the circle of its front wheels, widened
## where the tyres run out of cornering grip; the handbrake lets the tail come
## round (handbrake_turn_scale times the grip limit).
func road_yaw(fwd_speed: float, level: float, handbrake := false) -> float:
	var curvature := tan(deg_to_rad(params.max_wheel_angle) * clampf(level, -1.0, 1.0)) / params.wheelbase
	var v2 := fwd_speed * fwd_speed
	if params.cornering_grip > 0.0 and v2 > 1.0:
		var limit := params.cornering_grip / v2
		if handbrake:
			limit *= params.handbrake_turn_scale
		curvature = clampf(curvature, -limit, limit)
	return fwd_speed * curvature


## Tightest turning circle of a road car (centre of the car, px).
func min_circle() -> float:
	var r := params.wheelbase / tan(deg_to_rad(params.max_wheel_angle))
	return sqrt(r * r + params.rear_axle * params.rear_axle)


## Front wheel angle (radians, + = right) for drawing the wheels.
func wheel_angle() -> float:
	return deg_to_rad(params.max_wheel_angle) * steer_level


## Brakes bite over brake_rise_time and let go at once.
func _press_brakes(delta: float, pressed: bool) -> void:
	if not pressed:
		brake_level = 0.0
	elif params.brake_rise_time <= 0.0:
		brake_level = 1.0
	else:
		brake_level = minf(brake_level + delta / params.brake_rise_time, 1.0)


## Engine pull builds and fades at the rates in DrivingParams.
func _pull_engine(delta: float, pulling: bool) -> void:
	var time := params.throttle_rise_time if pulling else params.throttle_fall_time
	var target := 1.0 if pulling else 0.0
	if time <= 0.0:
		drive_level = target
	else:
		drive_level = move_toward(drive_level, target, delta / time)


## Advances velocity and heading by delta for one driver command.
## steer: -1 left .. +1 right. throttle (W): accelerate, or brake while rolling
## backwards. brake (S): brake, then reverse once stopped. handbrake (Space).
func update(delta: float, steer: float, throttle: bool, brake: bool, handbrake := false) -> void:
	_turn_wheel(delta, steer)
	var turn := 0.0
	if params.wheelbase > 0.0:
		turn = road_yaw(forward_speed(), steer_level, handbrake)
	else:
		turn = steer_level * deg_to_rad(params.turn_rate_degrees) * steer_factor(forward_speed())
		if handbrake:
			turn *= params.handbrake_turn_scale
	heading = wrapf(heading + turn * delta, -PI, PI)
	_apply_yaw(delta)

	var fwd_dir := forward()
	var side_dir := fwd_dir.orthogonal()
	var fwd := velocity.dot(fwd_dir)
	var side := velocity.dot(side_dir)
	# the engine pulls when W drives forward or S reverses from a standstill
	_pull_engine(delta, not handbrake and throttle != brake and (throttle or fwd <= STOP_SPEED))
	_press_brakes(delta, (brake and (throttle or fwd > STOP_SPEED)) or (throttle and fwd < -STOP_SPEED))
	var braking := params.brake_deceleration * brake_level

	if handbrake:
		fwd = move_toward(fwd, 0.0, params.handbrake_deceleration * delta)
	elif throttle and not brake:
		if fwd < -STOP_SPEED:
			fwd = move_toward(fwd, 0.0, braking * delta)
		elif fwd < params.max_speed:
			fwd = minf(fwd + pull_at(fwd, params.acceleration, params.max_speed) * drive_level * delta, params.max_speed)
		else:
			fwd = move_toward(fwd, params.max_speed, params.coast_deceleration * delta)
	elif brake and not throttle:
		if fwd > STOP_SPEED:
			fwd = move_toward(fwd, 0.0, braking * delta)
		elif fwd > -params.reverse_max_speed:
			fwd = maxf(fwd - pull_at(fwd, params.reverse_acceleration, params.reverse_max_speed) * drive_level * delta,
				-params.reverse_max_speed)
		else:
			fwd = move_toward(fwd, -params.reverse_max_speed, params.coast_deceleration * delta)
	elif brake and throttle:
		fwd = move_toward(fwd, 0.0, braking * delta)
	else:
		fwd = move_toward(fwd, 0.0, params.coast_deceleration * delta)

	var grip_scale := params.handbrake_grip_scale if handbrake else 1.0
	# a road car turns round its rear axle, so its centre swings out a little
	var pivot := -turn * params.rear_axle if params.wheelbase > 0.0 else 0.0
	side = pivot + (side - pivot) * exp(-params.grip * grip_scale * delta)
	if params.tyre_grip > 0.0:
		side = move_toward(side, pivot, params.tyre_grip * grip_scale * delta)
	slip = side - pivot
	velocity = fwd_dir * fwd + side_dir * side


## Nobody at the wheel (handbrake on, in gear): a shoved car scrubs to a stop.
func update_parked(delta: float) -> void:
	_apply_yaw(delta)
	velocity = velocity.move_toward(Vector2.ZERO, params.parked_friction * delta)


func _apply_yaw(delta: float) -> void:
	if yaw_rate != 0.0:  # knocked by another car (see resolve_car_collision)
		heading = wrapf(heading + yaw_rate * delta, -PI, PI)
		yaw_rate *= exp(-params.contact_yaw_damping * delta)
		if absf(yaw_rate) < 0.01:
			yaw_rate = 0.0


## Moves position by velocity (used when no physics body integrates the motion).
func integrate(delta: float) -> void:
	position += velocity * delta


## Collision response against a wall with outward normal (pointing towards
## the car). Returns the share of the along-wall speed kept (for the rest of
## this tick's motion). With wall_friction the loss grows with how hard the car
## hits: a shallow scrape keeps most of its speed and turns the nose along the
## wall (wall_align, at most wall_align_rate per second of contact), a
## head-on hit stops it and bounces it back a little.
func apply_wall_collision(normal: Vector2, delta := 1.0 / 60.0) -> float:
	var into := velocity.dot(normal)
	if into >= 0.0:
		return 1.0
	var tangent := velocity - normal * into
	var keep := params.wall_tangent_retention
	if params.wall_friction >= 0.0:
		var along := tangent.length()
		keep = clampf(1.0 - params.wall_friction * -into / maxf(along, 0.001), 0.0, 1.0)
	velocity = tangent * keep - normal * into * params.wall_restitution
	if params.wall_align > 0.0 and tangent.length() > 1.0:
		var angle := atan2(-into, tangent.length())  # 0 = sliding along the wall
		var glance := 1.0 - clampf(angle / deg_to_rad(params.wall_glance_angle), 0.0, 1.0)
		if glance > 0.0:
			var along_dir := tangent.normalized()
			if forward().dot(along_dir) < 0.0:
				along_dir = -along_dir  # reversing along the wall: the tail leads
			var turn := angle_difference(heading, along_dir.angle()) * params.wall_align * glance
			if params.wall_align_rate > 0.0:
				turn = clampf(turn, -params.wall_align_rate * delta, params.wall_align_rate * delta)
			heading = wrapf(heading + turn, -PI, PI)
	return keep


## Equal-mass contact between two cars. normal points from b towards a.
## Only the closing velocity along the normal changes, identically for both cars.
## With the contact point (and both cars' centres), each car is also turned a
## little by where it was struck (rear quarter most, nose least).
static func resolve_car_collision(a: CarModel, b: CarModel, normal: Vector2, contact := Vector2.INF,
		a_centre := Vector2.ZERO, b_centre := Vector2.ZERO) -> void:
	var closing := (a.velocity - b.velocity).dot(normal)
	if closing >= 0.0:
		return
	var restitution := (a.params.car_restitution + b.params.car_restitution) * 0.5
	var impulse := -(1.0 + restitution) * closing * 0.5
	a.velocity += normal * impulse
	b.velocity -= normal * impulse
	if contact != Vector2.INF:
		a.apply_contact_yaw(contact - a_centre, normal * impulse)
		b.apply_contact_yaw(contact - b_centre, -normal * impulse)


## Yaw from an impulse j (px/s) received at offset r (px) from the car's centre.
func apply_contact_yaw(r: Vector2, j: Vector2) -> void:
	if params.contact_yaw_factor <= 0.0:
		return
	var along := r.dot(forward()) / params.car_half_length  # -1 tail .. +1 nose
	var where := params.contact_front_factor
	if along < 0.0:
		where = lerpf(params.contact_front_factor, 1.0, clampf(-along / 0.6, 0.0, 1.0))
	var kick := params.contact_yaw_factor * where * r.cross(j) / (params.car_half_length * params.car_half_length)
	yaw_rate = clampf(yaw_rate + kick, -params.contact_yaw_max, params.contact_yaw_max)
