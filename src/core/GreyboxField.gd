extends Node3D
## Greybox sandbox: flat field, one player, camera chase.
## Purpose is to validate movement feel — weight, accel, turn radius.

@onready var player: PlayerEntity = $Player
@onready var camera: Camera3D = $Camera3D
@onready var readout: Label = $HUD/Readout

var _cam_offset := Vector3(0.0, 5.5, 9.0)

func _ready() -> void:
	player.is_user_controlled = true
	player.measurables.compute()
	_update_readout()

func _process(delta: float) -> void:
	# Snappy camera chase: follows position directly, eases only the look.
	var focus := player.global_position
	var desired := focus + _cam_offset
	camera.global_position = camera.global_position.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
	camera.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
	_update_readout()

func _update_readout() -> void:
	var m := player.measurables
	var h := HealthManager.get_state(player.player_id)
	readout.text = "\n".join([
		"FOS Sports Football — greybox",
		"move: WASD / left stick     sprint: Shift / B",
		"",
		"40: %.2fs   10-split: %.2fs   3-cone: %.2fs" % [m.forty_yard_s, m.ten_yard_split_s, m.three_cone_s],
		"wt: %.0fkg  top speed: %.2f m/s (%.1f mph)" % [m.mass_kg, m.top_speed_mps, m.top_speed_mps * 2.23694],
		"accel: %.2f m/s²   turn: %.0f°/s   reach: %.2fm" % [m.accel_mps2, m.turn_rate_deg, m.reach_m],
		"",
		"current: %.1f mph   stamina: %.0f%%   traction: %.2f" % [player.speed_mph(), h.stamina * 100.0, EnvironmentManager.traction],
	])
