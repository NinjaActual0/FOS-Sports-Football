@tool
class_name PlayerMeasurables
extends Resource
## Real-world combine measurables. Every gameplay trait is *derived* from these,
## so two players with different bodies genuinely move differently.

@export var position: String = "ATH"
@export var handedness: String = "R"

@export_group("Anthropometrics")
@export var height_cm: float = 185.0
@export var weight_kg: float = 95.0
@export var wingspan_cm: float = 190.0
@export var arm_length_cm: float = 85.0
@export var hand_size_cm: float = 24.0

@export_group("Speed and Explosion")
@export_range(4.2, 6.5, 0.01) var forty_yard_s: float = 4.80
@export_range(1.30, 2.20, 0.01) var ten_yard_split_s: float = 1.65
@export_range(3.8, 5.5, 0.01) var twenty_yard_shuttle_s: float = 4.40

@export_group("Agility")
@export_range(6.4, 8.5, 0.01) var three_cone_s: float = 7.00
@export_range(3.8, 5.5, 0.01) var short_shuttle_s: float = 4.25

@export_group("Power")
@export_range(25.0, 120.0, 0.5) var vertical_jump_cm: float = 85.0
@export_range(150.0, 380.0, 1.0) var broad_jump_cm: float = 290.0
@export_range(0, 50, 1) var bench_press_reps: int = 20

# --- Derived, computed from the numbers above. Not authored by hand. ---
var accel_mps2: float = 6.0
var top_speed_mps: float = 7.6
var decel_mps2: float = 8.0
var turn_rate_deg: float = 220.0
var mass_kg: float = 95.0
var reach_m: float = 1.0
var catch_diameter_m: float = 0.55
var break_tackle_force: float = 1.0

const YARD_M := 0.9144

func compute() -> void:
	mass_kg = weight_kg

	# 40 time -> top speed. A 4.40 gives ~8.3 m/s, a 5.00 gives ~7.3 m/s.
	var avg_40_speed := (40.0 * YARD_M) / maxf(forty_yard_s, 4.0)
	# The 10-yard split tells us how much of that speed arrives early.
	var burst := clampf(1.70 / maxf(ten_yard_split_s, 1.3), 0.80, 1.30)
	top_speed_mps = avg_40_speed * clampf(0.92 + burst * 0.10, 0.90, 1.06)

	# Acceleration in m/s^2: burst sets the curve, mass resists it.
	accel_mps2 = 5.2 * burst * clampf(95.0 / maxf(weight_kg, 60.0), 0.75, 1.20)
	decel_mps2 = 7.0 * (0.6 + 0.4 * burst)

	# Turning: 3-cone is the best proxy for hip fluidity. Lower time = tighter turn.
	var cone := clampf(7.35 / maxf(three_cone_s, 6.2), 0.85, 1.20)
	turn_rate_deg = 200.0 * cone * clampf(80.0 / maxf(weight_kg, 60.0), 0.85, 1.10)

	# Reach: arm length plus half the frame. Drives catch and tackle radius.
	reach_m = (arm_length_cm / 100.0) + (height_cm / 200.0)
	catch_diameter_m = clampf(hand_size_cm / 100.0 * 2.2 + 0.28, 0.40, 0.85)

	# Mass + bench press = how hard he is to bring down / how hard he hits.
	break_tackle_force = (weight_kg / 95.0) * (1.0 + bench_press_reps / 40.0)

## Convenience: fill from a plain dictionary (used by roster import).
func from_dict(d: Dictionary) -> void:
	var props := {}
	for p in get_property_list():
		if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props[p.name] = true
	for key in d.keys():
		if props.has(key):
			set(key, d[key])
	compute()
