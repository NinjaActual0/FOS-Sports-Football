@tool
class_name PlayerMeasurables
extends Resource

@export var position: String = \"ATH\"
@export var handedness: String = \"R\"

# Anthro
@export var height_cm: float = 185.0
@export var weight_kg: float = 95.0
@export var wingspan_cm: float = 190.0
@export var arm_length_cm: float = 85.0
@export var hand_size_cm: float = 24.0

# Speed/Explosion
@export var forty_yard_s: float = 4.80
@export var ten_yard_split_s: float = 1.65
@export var twenty_yard_shuttle_s: float = 4.40

# Agility
@export var three_cone_s: float = 7.00
@export var short_shuttle_s: float = 4.25

# Power/Athleticism
@export var vertical_jump_cm: float = 85.0
@export var broad_jump_cm: float = 290.0
@export var bench_press_reps: int = 20

# Derived (computed)
var accel_factor: float = 1.0
var top_speed_mps: float = 8.5
var mass_kg: float = 95.0
var agility_factor: float = 1.0
var reach_factor: float = 1.0
var momentum_factor: float = 1.0

func compute() -> void:
	mass_kg = weight_kg
	# Burst from 10-yard split (lower is better)
	var burst = clampf(1.65 / maxf(ten_yard_split_s, 1.0), 0.8, 1.3)
	accel_factor = burst
	# Top speed from 40 (lower better) with mass influence
	var speed_raw = 36.576 / maxf(forty_yard_s, 4.2) # yards to meters
	top_speed_mps = speed_raw * clampf(95.0 / maxf(weight_kg, 70.0), 0.85, 1.05)
	# Agility from 3-cone
	agility_factor = clampf(7.0 / maxf(three_cone_s, 6.5), 0.9, 1.15)
	# Reach
	reach_factor = clampf((arm_length_cm + wingspan_cm) / (85.0 + 190.0), 0.9, 1.1)
	momentum_factor = mass_kg / 95.0
