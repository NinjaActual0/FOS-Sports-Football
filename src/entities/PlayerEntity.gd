class_name PlayerEntity
extends CharacterBody3D
## A single football player. Movement is generated from his measurables,
## modified by fatigue/injury and the current field traction. There is no
## hidden "win the rep" check anywhere in this class.

@export var measurables: PlayerMeasurables
@export var player_id: String = ""
@export var is_user_controlled: bool = false
@export_range(0.0, 1.0) var effort: float = 1.0
@export var sprint_mult: float = 1.22

var facing: Vector3 = Vector3.FORWARD

func _ready() -> void:
	if measurables == null:
		measurables = PlayerMeasurables.new()
	measurables.compute()
	if player_id == "":
		player_id = str(get_instance_id())

func _physics_process(delta: float) -> void:
	var wish := Vector3.ZERO
	if is_user_controlled:
		wish = _read_input()

	var health := HealthManager.get_state(player_id)
	var traction := EnvironmentManager.traction

	# Desired horizontal velocity.
	var target_speed: float = measurables.top_speed_mps * health.top_speed_modifier()
	if Input.is_action_pressed("sprint"):
		target_speed *= sprint_mult
	var target := wish * target_speed

	# Accelerate toward the target using real accel curves, not a fixed lerp.
	var current := Vector3(velocity.x, 0.0, velocity.z)
	var diff := target - current
	var accel: float = measurables.accel_mps2 * health.accel_modifier() * traction
	if wish == Vector3.ZERO:
		accel = measurables.decel_mps2 * traction

	var max_step := accel * delta
	var applied := diff.limit_length(max_step) if max_step > 0.0 else Vector3.ZERO
	current += applied

	velocity.x = current.x
	velocity.z = current.z

	# Gravity so the body stays grounded; Jolt handles the rest.
	if not is_on_floor():
		velocity += PhysicsManager.gravity_vector() * delta

	move_and_slide()

	# Turn the body toward travel direction at a rate limited by agility.
	if current.length() > 0.15:
		facing = facing.slerp(current.normalized(), clampf(measurables.turn_rate_deg / 90.0 * delta, 0.0, 1.0))

	# Physical cost of this frame of effort.
	var load := current.length() / maxf(measurables.top_speed_mps, 0.1) * effort
	HealthManager.exert(player_id, load, delta)

func _read_input() -> Vector3:
	var v := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var dir := Vector3(v.x, 0.0, v.y)
	if dir.length() > 1.0:
		dir = dir.normalized()
	return dir

## Speed readout in mph, used by the debug HUD.
func speed_mph() -> float:
	return Vector3(velocity.x, 0.0, velocity.z).length() * 2.23694
