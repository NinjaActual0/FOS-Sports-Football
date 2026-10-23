@tool
class_name PlayerEntity
extends CharacterBody3D

@export var measurables: Resource
var accel_factor: float = 1.0
var top_speed_mps: float = 8.5
var mass_kg: float = 95.0

func _ready() -> void:
	if measurables and measurables.has_method(\"compute\"):
		measurables.compute()
		accel_factor = measurables.accel_factor
		top_speed_mps = measurables.top_speed_mps
		mass_kg = measurables.mass_kg
		mass = mass_kg

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector(\"move_left\", \"move_right\", \"move_forward\", \"move_backward\")
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		velocity.x = lerp(velocity.x, dir.x * top_speed_mps * accel_factor, delta * 8.0)
		velocity.z = lerp(velocity.z, dir.z * top_speed_mps * accel_factor, delta * 8.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta * 10.0)
		velocity.z = lerp(velocity.z, 0.0, delta * 10.0)
	move_and_slide()
