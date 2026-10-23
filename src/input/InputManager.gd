extends Node
class_name InputManager

var current_device: int = -1 # -1 KBM, 0+ gamepad
var glyph_set: String = \"xbox\" # xbox, playstation

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != event.device:
			current_device = event.device
			_detect_glyph_set()
	elif event is InputEventKey or event is InputEventMouseButton:
		if current_device != -1:
			current_device = -1
			glyph_set = \"kbm\"

func _detect_glyph_set() -> void:
	# Basic detection - can be expanded
	var name = Input.get_joy_name(current_device).to_lower()
	if \"sony\" in name or \"playstation\" in name or \"dualshock\" in name or \"dualsense\" in name:
		glyph_set = \"playstation\"
	else:
		glyph_set = \"xbox\"
