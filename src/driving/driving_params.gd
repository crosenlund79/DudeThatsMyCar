class_name DrivingParams
extends Resource
## Handling of one vehicle type. Units: world pixels and seconds.
##
## Carried over from HyperCars (the approved, well-liked handling): the same
## momentum / grip slide model, wall and car-to-car contact rules and, for the
## first car, numbers close to the HyperCars baseline (top speed 420, accel 260,
## brake 520, turn 210 deg/s, grip 4.5). Added for city driving: separate
## throttle and brake, reverse gear, a handbrake, steering that needs the car to
## roll (no spinning on the spot), and a parked state. ALL VALUES PROVISIONAL.

## Name shown to the player ("Sedan", "Roadster").
@export var display_name := "Car"
## Top forward speed (px/s).
@export var max_speed: float = 420.0
## Forward acceleration with W held (px/s^2).
@export var acceleration: float = 260.0
## Deceleration with neither W nor S held: engine braking and rolling (px/s^2).
@export var coast_deceleration: float = 140.0
## Braking with S held while rolling forward, or W while rolling backwards (px/s^2).
@export var brake_deceleration: float = 520.0
## Reverse gear: S held at a standstill (or rolling backwards).
@export var reverse_max_speed: float = 150.0
@export var reverse_acceleration: float = 220.0
## Rotation speed at full steering (degrees/s).
@export var turn_rate_degrees: float = 210.0
## Below this speed (px/s) steering fades out linearly, so a car at rest
## cannot turn; rolling backwards steers the other way, like a real car.
@export var full_steer_speed: float = 90.0
## How fast sideways (sliding) velocity decays, per second. Lower = more slide.
@export var grip: float = 4.5
## Handbrake (Space): slows forward motion, lets the car slide (grip x scale)
## and turns it a little faster, for handbrake turns into alleys.
@export var handbrake_deceleration: float = 330.0
@export_range(0.0, 1.0) var handbrake_grip_scale := 0.3
@export var handbrake_turn_scale := 1.35
## An unoccupied car (handbrake on, in gear) that was shoved: how fast it stops (px/s^2).
@export var parked_friction: float = 900.0
## Fraction of the into-wall speed bounced back on impact (0..1).
@export_range(0.0, 1.0) var wall_restitution: float = 0.3
## Fraction of the along-wall speed kept on impact (0..1).
@export_range(0.0, 1.0) var wall_tangent_retention: float = 0.75
## Car-to-car contact: fraction of the closing speed bounced apart (0..1). Equal masses.
@export_range(0.0, 1.0) var car_restitution: float = 0.4

## Contact yaw (HyperCars): a car struck behind its centre turns more than one
## struck at the nose; capped and quickly damped. contact_yaw_factor = 0 = off.
@export var contact_yaw_factor := 0.9
@export var contact_front_factor := 0.3
@export var contact_yaw_max := 1.6
@export var contact_yaw_damping := 4.0
## Half the car's length (px), the lever arm for contact yaw.
@export var car_half_length := 38.0
