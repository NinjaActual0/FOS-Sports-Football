extends Node3D
## Greybox sandbox: flat field, one player, chase cam.
## Purpose is to validate movement feel — weight, accel, cut severity, spin cost.

const HINT_CONTROLLER := "No controller detected. Plug one in — Xbox, PlayStation, and generic XInput pads all work."

@onready var player: PlayerEntity = $Player
@onready var camera: Camera3D = $Camera3D
@onready var readout: Label = $HUD/Readout
@onready var hint: Label = $HUD/Hint
@onready var mesh: MeshInstance3D = $Player/Visual/MeshInstance3D

var _cam_offset := Vector3(0.0, 5.5, 9.0)
var _mat: StandardMaterial3D
var _last_cut := 0.0
var _last_cut_loss := 0.0
var _last_cut_age := 99.0

func _ready() -> void:
	player.is_user_controlled = true
	player.measurables.compute()
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.85, 0.87, 0.92)
	mesh.material_override = _mat
	player.cut_performed.connect(_on_cut)
	player.spin_started.connect(_on_spin)
	InputManager.device_changed.connect(func(_g, _c): _refresh_hint())
	_refresh_hint()

func _process(delta: float) -> void:
	var focus := player.global_position
	var desired := focus + _cam_offset
	camera.global_position = camera.global_position.lerp(desired, clampf(delta * 6.0, 0.0, 1.0))
	camera.look_at(focus + Vector3.UP * 1.2, Vector3.UP)
	_last_cut_age += delta
	_update_state_visual()
	_update_readout()

func _update_state_visual() -> void:
	if player.is_spinning:
		_mat.albedo_color = Color(0.30, 0.80, 0.95)
	elif player.is_planting:
		_mat.albedo_color = Color(0.98, 0.82, 0.25)
	else:
		_mat.albedo_color = Color(0.85, 0.87, 0.92)

func _on_cut(angle_deg: float, speed_lost: float) -> void:
	_last_cut = angle_deg
	_last_cut_age = 0.0

func _on_spin(_direction: int) -> void:
	pass

func _refresh_hint() -> void:
	hint.visible = not InputManager.has_gamepad()
	if hint.visible:
		hint.text = HINT_CONTROLLER
	else:
		hint.text = ""

func _device_line() -> String:
	if not InputManager.has_gamepad():
		return "input: keyboard + mouse"
	var pad_name := Input.get_joy_name(InputManager.current_device)
	var glyph_names: Array[String] = ["keyboard", "xbox", "playstation"]
	var set_name: String = glyph_names[InputManager.glyph_set]
	return "input: %s  (glyphs: %s)" % [pad_name, set_name]

func _update_readout() -> void:
	var m := player.measurables
	var h := HealthManager.get_state(player.player_id)

	var cut_line := "cut: —"
	if _last_cut_age < 1.2:
		cut_line = "cut: %.0f°   speed lost: %.1f mph" % [_last_cut, 0.0]

	var state := "grounded"
	if player.is_spinning:
		state = "SPINNING"
	elif player.is_planting:
		state = "PLANTING"

	readout.text = "\n".join([
		"FOS Sports Football — greybox",
		"move %s     sprint %s     spin %s" % [
			InputManager.glyph("move"),
			InputManager.glyph("sprint"),
			InputManager.glyph("spin"),
		],
		"",
		"40: %.2fs   10-split: %.2fs   3-cone: %.2fs" % [m.forty_yard_s, m.ten_yard_split_s, m.three_cone_s],
		"wt: %.0fkg  top speed: %.2f m/s (%.1f mph)" % [m.mass_kg, m.top_speed_mps, m.top_speed_mps * 2.23694],
		"accel: %.2f m/s²   turn: %.0f°/s   reach: %.2fm" % [m.accel_mps2, m.turn_rate_deg, m.reach_m],
		"",
		"speed: %.1f mph   stamina: %.0f%%   traction: %.2f" % [player.speed_mph(), h.stamina * 100.0, EnvironmentManager.traction],
		"state: %-9s %s   cuts: %d" % [state, cut_line, player.cuts_this_play],
		_device_line(),
		"",
		"try: sprint straight, then slam a hard left at full speed.",
		"try: sprint, then spin — you keep momentum but lose your steer.",
	])
