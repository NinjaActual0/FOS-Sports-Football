class_name PlayerEntity
extends CharacterBody3D
## A single football player.
##
## Movement is generated from measurables plus the current physical state of the
## body and the field. There is no hidden "win the rep" check anywhere in this
## class.
##
## Cutting and spinning are NOT animations with success rolls. They are two ways
## the same force budget gets spent:
##
##   Cut   - you must kill forward momentum before the new direction can take
##           over. Sharp angle at high speed = more speed lost. A well-timed
##           plant trades less speed because the planted foot can push harder
##           laterally.
##   Spin  - you keep most of your momentum but give up your ability to
##           accelerate laterally while rotating. Good for escaping leverage
##           when a defender is committed; bad if you spin into open space.

signal cut_performed(angle_deg: float, speed_lost: float)
signal spin_started(direction: int)
signal juke_performed(direction: int)

const CUT_ANGLE_DEG := 32.0
const PLANT_TIME := 0.17
const PLANT_COOLDOWN := 0.12
const SPIN_DURATION := 0.42
const SPIN_COOLDOWN := 0.85
const SPIN_SPEED_COST := 0.12
const SPIN_LATERAL_LOCK := 0.15

## Juke: a push off the outside foot. Unlike a cut it does NOT kill your drive -
## it adds sideways momentum on top of the speed you already carry, and the turf
## scrubs that extra away over about half a second. You stay committed for a beat,
## so a juke into traffic is a real mistake.
const JUKE_COOLDOWN := 0.55
const JUKE_DURATION := 0.28
const JUKE_MIN_SPEED_FRAC := 0.35
const JUKE_BASE_MPS := 3.55
const JUKE_DECAY_MPS2 := 7.0
const JUKE_FORWARD_COST := 0.94
const JUKE_STEER_LOCK := 0.35

## Body roll, purely presentational, but it is the cue a defender will read later.
const MAX_LEAN := 0.30
const LEAN_RESPONSE := 9.0

@export var measurables: PlayerMeasurables
@export var player_id: String = ""
@export var is_user_controlled: bool = false
@export_range(0.0, 1.0) var effort: float = 1.0
@export var sprint_mult: float = 1.22

var facing: Vector3 = Vector3.FORWARD

# --- runtime state (readable by other systems, e.g. tackling) ---
var is_spinning: bool = false
var spin_charge: float = 1.0        ## 1 = fully effective, decays toward 0 while spinning
var is_planting: bool = false
var plant_charge: float = 1.0       ## how well the foot is set during a cut
var is_juking: bool = false
var last_juke_direction: int = 0    ## -1 left, +1 right
var lean: float = 0.0               ## -1 = rolled left, +1 = rolled right
var last_cut_angle: float = 0.0
var cuts_this_play: int = 0

var _spin_timer: float = 0.0
var _spin_cooldown: float = 0.0
var _spin_sign: float = 1.0
var _plant_timer: float = 0.0
var _plant_cooldown: float = 0.0
var _juke_vel: Vector3 = Vector3.ZERO   ## momentum from the push, scrubbed by turf
var _juke_timer: float = 0.0
var _juke_cooldown: float = 0.0
var _prev_move_dir: Vector3 = Vector3.ZERO
@onready var _visual: Node3D = get_node_or_null("Visual") as Node3D

func _ready() -> void:
	if measurables == null:
		measurables = PlayerMeasurables.new()
	measurables.compute()
	if player_id == "":
		player_id = str(get_instance_id())

func _physics_process(delta: float) -> void:
	var health := HealthManager.get_state(player_id) as HealthState
	var traction := EnvironmentManager.traction
	var max_speed: float = measurables.top_speed_mps * health.top_speed_modifier()
	if is_user_controlled and Input.is_action_pressed("sprint"):
		max_speed *= sprint_mult

	# The juke burst is momentum the feet did not have to earn this frame, so it
	# rides on top of the force budget instead of being clamped by it. Invariant:
	# velocity.xz == self-powered velocity + _juke_vel, at all times.
	var wish := _read_input() if is_user_controlled else Vector3.ZERO
	if _juke_timer > 0.0:
		wish *= JUKE_STEER_LOCK

	_tick_timers(delta)
	_handle_spin_input(delta, _self_velocity(), wish)
	_handle_juke_input()

	# Derive the force budget AFTER the timers and the move inputs, so a juke that
	# just fired is already subtracted out of the budget it was paid from.
	var burst := _juke_vel
	var current := _self_velocity()
	var speed := current.length()

	# ---- Spin: momentum is preserved, steering is not --------------------
	if is_spinning:
		var spin_rate := (PI * 1.15) / SPIN_DURATION * _spin_sign
		current = current.rotated(Vector3.UP, spin_rate * delta)
		# Friction on a single planted foot is worse than two.
		current *= 1.0 - (0.35 * delta / SPIN_DURATION)
		spin_charge = maxf(spin_charge - delta / SPIN_DURATION, 0.0)
		# Spinning costs you your lateral push.
		var drift := wish * max_speed * SPIN_LATERAL_LOCK * delta * 2.0
		current += drift
		current = current.limit_length(max_speed)
	else:
		current = _resolve_movement(current, speed, wish, max_speed, health, traction, delta)

	velocity.x = current.x + burst.x
	velocity.z = current.z + burst.z

	if not is_on_floor():
		velocity += PhysicsManager.gravity_vector() * delta

	move_and_slide()

	# Lean the body into travel. Turn rate comes from agility (3-cone/shuttle).
	# Facing chases the feet, not the juke slide: a juke is supposed to keep your
	# shoulders square while your feet go sideways, which is what a defender has
	# to read.
	var travel := Vector3(velocity.x, 0.0, velocity.z)
	var steer := _self_velocity()
	if steer.length() > 0.15:
		var turn := deg_to_rad(measurables.turn_rate_deg * (0.6 if is_spinning else 1.0))
		facing = facing.slerp(steer.normalized(), clampf(turn * delta, 0.0, 1.0))

	_update_lean(travel, max_speed, delta)

	# Point the visual body where the player is actually facing. This is purely
	# presentational - the capsule is radially symmetric, so the greybox adds a
	# shoulder bar and a floating chevron to make the front readable.
	if _visual != null:
		_visual.rotation.y = atan2(-facing.x, -facing.z)
		_visual.rotation.z = -lean * MAX_LEAN

	# Physical cost of the effort actually exerted this frame.
	var load := travel.length() / maxf(measurables.top_speed_mps, 0.1) * effort
	HealthManager.exert(player_id, load, delta)

## Velocity the feet are actually driving, i.e. everything except the decaying
## sideways push from a juke.
func _self_velocity() -> Vector3:
	return Vector3(velocity.x - _juke_vel.x, 0.0, velocity.z - _juke_vel.z)

## Core force budget. Splits the desired velocity into the component along the
## player's momentum and the component lateral to it, then limits each by what
## the body and the turf can actually deliver.
func _resolve_movement(
	current: Vector3,
	speed: float,
	wish: Vector3,
	max_speed: float,
	health: HealthState,
	traction: float,
	delta: float
) -> Vector3:
	if wish == Vector3.ZERO:
		var decel := measurables.decel_mps2 * traction
		return current.move_toward(Vector3.ZERO, decel * delta)

	var agility := clampf(measurables.turn_rate_deg / 200.0, 0.8, 1.25)
	var vdir := current.normalized() if speed > 0.15 else wish

	# --- Cut detection: a real change of direction while carrying speed ---
	var angle := rad_to_deg(vdir.angle_to(wish)) if speed > 0.15 else 0.0
	if _plant_timer <= 0.0 and _plant_cooldown <= 0.0 \
			and angle >= CUT_ANGLE_DEG and speed > measurables.top_speed_mps * 0.30:
		_begin_cut(angle, agility, traction)

	# --- Longitudinal: pushing forward / braking ---
	var accel_long := measurables.accel_mps2 * health.accel_modifier() * traction
	var target_long := wish.dot(vdir) * max_speed
	var new_speed := maxf(move_toward(speed, target_long, accel_long * delta), 0.0)

	# --- Lateral: this is what makes a cut feel like a cut ---
	var lat_dir := wish - vdir * wish.dot(vdir)
	var lat_desired := lat_dir * max_speed
	var accel_lat := measurables.accel_mps2 * 0.55 * agility * traction
	if is_planting:
		# A set foot can push harder sideways than it can accelerate forward.
		accel_lat *= 1.0 + 0.9 * plant_charge * agility
		plant_charge = maxf(plant_charge - delta / PLANT_TIME, 0.0)

	var lateral := current - vdir * speed
	lateral += lat_desired.limit_length(accel_lat * delta)
	# A hard plant scrubs the lateral drift you were carrying.
	if is_planting:
		lateral *= 1.0 - clampf(0.9 * delta / PLANT_TIME, 0.0, 0.9)

	var result := vdir * new_speed + lateral
	if result.length() > max_speed:
		result = result.normalized() * max_speed
	return result

func _begin_cut(angle: float, agility: float, traction: float) -> void:
	# Momentum you cannot keep. Steeper angle and worse footing cost more.
	var loss := sin(deg_to_rad(angle)) * (1.35 - 0.45 * agility) / maxf(traction, 0.4)
	loss = clampf(loss, 0.0, 0.55)
	var speed := Vector3(velocity.x, 0.0, velocity.z).length()
	velocity.x *= 1.0 - loss
	velocity.z *= 1.0 - loss

	_plant_timer = PLANT_TIME
	_plant_cooldown = PLANT_TIME + PLANT_COOLDOWN
	plant_charge = clampf(agility * (1.0 - angle / 180.0) + 0.25, 0.2, 1.0)
	is_planting = true
	last_cut_angle = angle
	cuts_this_play += 1
	cut_performed.emit(angle, speed - Vector3(velocity.x, 0.0, velocity.z).length())

func _handle_spin_input(delta: float, current: Vector3, wish: Vector3) -> void:
	if _spin_cooldown > 0.0 or is_spinning:
		return
	if not Input.is_action_just_pressed("spin"):
		return
	var speed := current.length()
	if speed < measurables.top_speed_mps * 0.20:
		return  # you cannot spin out of a standstill

	# Spin away from the way the stick is going, which is how defenders get
	# their leverage broken. No stick input = spin right.
	_spin_sign = 1.0
	if wish != Vector3.ZERO and current.dot(wish) > 0.0:
		_spin_sign = -1.0

	is_spinning = true
	_spin_timer = SPIN_DURATION
	spin_charge = 1.0
	velocity.x *= 1.0 - SPIN_SPEED_COST
	velocity.z *= 1.0 - SPIN_SPEED_COST
	# Carry the juke burst through the same cost so velocity stays consistent.
	_juke_vel *= 1.0 - SPIN_SPEED_COST
	spin_started.emit(int(_spin_sign))

func _tick_timers(delta: float) -> void:
	if _plant_cooldown > 0.0:
		_plant_cooldown -= delta
	if _plant_timer > 0.0:
		_plant_timer -= delta
		if _plant_timer <= 0.0:
			is_planting = false
	if _juke_cooldown > 0.0:
		_juke_cooldown -= delta
	if _juke_timer > 0.0:
		_juke_timer -= delta
		if _juke_timer <= 0.0:
			is_juking = false
	if _juke_vel.length_squared() > 0.0001:
		if is_on_floor():
			# Turf friction eats the push. Nothing outlives ~0.5 s.
			var before := _juke_vel
			var decay := JUKE_DECAY_MPS2 * EnvironmentManager.traction
			_juke_vel = _juke_vel.move_toward(Vector3.ZERO, decay * delta)
			# Scrub the same amount off the real velocity so the two stay in sync.
			velocity.x -= before.x - _juke_vel.x
			velocity.z -= before.z - _juke_vel.z
	else:
		_juke_vel = Vector3.ZERO
	if is_spinning:
		_spin_timer -= delta
		if _spin_timer <= 0.0:
			is_spinning = false
			spin_charge = 0.0
			_spin_cooldown = SPIN_COOLDOWN
	elif _spin_cooldown > 0.0:
		_spin_cooldown -= delta

func _handle_juke_input() -> void:
	if not is_user_controlled or is_spinning:
		return
	# The stick is screen-relative but the push is body-relative, so translate.
	# Facing the camera would otherwise flip your jukes left for right.
	var body_right := facing.cross(Vector3.UP)
	if body_right.length_squared() < 0.0001:
		return
	var screen_right := _input_right()
	var side := 1.0 if screen_right.dot(body_right.normalized()) >= 0.0 else -1.0
	if Input.is_action_just_pressed("juke_right"):
		perform_juke(int(side))
	elif Input.is_action_just_pressed("juke_left"):
		perform_juke(int(-side))

## Push off the outside foot. Public because AI, coach mode and sim must all use
## the same move the player does. Returns false when the body could not do it.
func perform_juke(direction: int) -> bool:
	if direction == 0 or is_spinning or is_juking:
		return false
	if _juke_cooldown > 0.0 or not is_on_floor():
		return false

	var carried := Vector3(velocity.x - _juke_vel.x, 0.0, velocity.z - _juke_vel.z)
	if carried.length() < measurables.top_speed_mps * JUKE_MIN_SPEED_FRAC:
		return false  # you cannot juke out of a standstill

	var agility := clampf(measurables.turn_rate_deg / 200.0, 0.8, 1.25)
	var right := facing.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = Vector3.RIGHT
	right = right.normalized()

	# Weight transfer costs a little drive before the push lands. The push is added
	# to _juke_vel first so velocity and the burst never disagree about who owns
	# the sideways momentum - callers may invoke this outside _physics_process.
	_juke_vel += right * float(direction) * JUKE_BASE_MPS * agility
	velocity.x = carried.x * JUKE_FORWARD_COST + _juke_vel.x
	velocity.z = carried.z * JUKE_FORWARD_COST + _juke_vel.z

	is_juking = true
	_juke_timer = JUKE_DURATION
	_juke_cooldown = JUKE_COOLDOWN
	last_juke_direction = direction
	juke_performed.emit(direction)
	return true

## Roll the body toward the direction the feet are actually sliding.
func _update_lean(travel: Vector3, max_speed: float, delta: float) -> void:
	var right := facing.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		return
	var lateral := travel.dot(right.normalized())
	var ratio := clampf(lateral / maxf(max_speed, 1.0), -1.0, 1.0)
	# Square-root curve so a 20-25 degree juke still reads as a lean instead of
	# vanishing into rounding error on a greybox capsule.
	var target := signf(ratio) * sqrt(absf(ratio))
	lean = lerpf(lean, target, clampf(delta * LEAN_RESPONSE, 0.0, 1.0))

func _read_input() -> Vector3:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	# Input is screen-relative, not world-relative: "right" must mean right on
	# screen no matter which way the body or the camera happens to be pointing.
	var dir := _input_right() * v.x + _input_forward() * (-v.y)
	return dir.limit_length(1.0)

## Ground-projected camera basis. Falls back to world axes when there is no
## camera (headless tests, sim-only runs).
func _input_right() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.RIGHT
	var r := cam.global_transform.basis.x
	r.y = 0.0
	return r.normalized() if r.length_squared() > 0.0001 else Vector3.RIGHT

func _input_forward() -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.FORWARD
	var f := -cam.global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 0.0001 else Vector3.FORWARD

## Speed readout in mph, used by the debug HUD.
func speed_mph() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length() * 2.23694
