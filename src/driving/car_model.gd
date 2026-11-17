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


func _init(p_params: DrivingParams = null) -> void:
	params = p_params if p_params != null else DrivingParams.new()


func forward() -> Vector2:
	return Vector2.from_angle(heading)


func forward_speed() -> float:
	return velocity.dot(forward())


func lateral_speed() -> float:
	return velocity.dot(forward().orthogonal())


## Share of full steering available at a forward speed: none at rest, full
## from full_steer_speed; negative while rolling backwards (the car turns the
## other way, as a real car reversing does).
func steer_factor(fwd_speed: float) -> float:
	var f := 1.0
	if params.full_steer_speed > 0.0:
		f = clampf(absf(fwd_speed) / params.full_steer_speed, 0.0, 1.0)
	return -f if fwd_speed < -STOP_SPEED else f


## Advances velocity and heading by delta for one driver command.
## steer: -1 left .. +1 right. throttle (W): accelerate, or brake while rolling
## backwards. brake (S): brake, then reverse once stopped. handbrake (Space).
func update(delta: float, steer: float, throttle: bool, brake: bool, handbrake := false) -> void:
	var turn := clampf(steer, -1.0, 1.0) * deg_to_rad(params.turn_rate_degrees) * steer_factor(forward_speed())
	if handbrake:
		turn *= params.handbrake_turn_scale
	heading = wrapf(heading + turn * delta, -PI, PI)
	_apply_yaw(delta)

	var fwd_dir := forward()
	var side_dir := fwd_dir.orthogonal()
	var fwd := velocity.dot(fwd_dir)
	var side := velocity.dot(side_dir)

	if handbrake:
		fwd = move_toward(fwd, 0.0, params.handbrake_deceleration * delta)
	elif throttle and not brake:
		if fwd < -STOP_SPEED:
			fwd = move_toward(fwd, 0.0, params.brake_deceleration * delta)
		elif fwd < params.max_speed:
			fwd = minf(fwd + params.acceleration * delta, params.max_speed)
		else:
			fwd = move_toward(fwd, params.max_speed, params.coast_deceleration * delta)
	elif brake and not throttle:
		if fwd > STOP_SPEED:
			fwd = move_toward(fwd, 0.0, params.brake_deceleration * delta)
		elif fwd > -params.reverse_max_speed:
			fwd = maxf(fwd - params.reverse_acceleration * delta, -params.reverse_max_speed)
		else:
			fwd = move_toward(fwd, -params.reverse_max_speed, params.coast_deceleration * delta)
	elif brake and throttle:
		fwd = move_toward(fwd, 0.0, params.brake_deceleration * delta)
	else:
		fwd = move_toward(fwd, 0.0, params.coast_deceleration * delta)

	var grip := params.grip * (params.handbrake_grip_scale if handbrake else 1.0)
	side *= exp(-grip * delta)
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


## Collision response against a wall with outward normal (pointing towards the car).
func apply_wall_collision(normal: Vector2) -> void:
	var into := velocity.dot(normal)
	if into >= 0.0:
		return
	var tangent := velocity - normal * into
	velocity = tangent * params.wall_tangent_retention - normal * into * params.wall_restitution


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
