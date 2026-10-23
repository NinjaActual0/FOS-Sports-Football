extends Node
## Tracks the active input device and exposes the right button glyphs.
## Autoloaded as `InputManager`.

enum GlyphSet { KEYBOARD, XBOX, PLAYSTATION }

const GLYPHS := {
	GlyphSet.KEYBOARD: {
		"confirm": "Enter",
		"cancel": "Esc",
		"pass": "LMB",
		"sprint": "Shift",
		"tackle": "F",
	},
	GlyphSet.XBOX: {
		"confirm": "A",
		"cancel": "B",
		"pass": "X",
		"sprint": "B",
		"tackle": "Y",
	},
	GlyphSet.PLAYSTATION: {
		"confirm": "Cross",
		"cancel": "Circle",
		"pass": "Square",
		"sprint": "Circle",
		"tackle": "Triangle",
	},
}

var current_device: int = -1
var glyph_set: GlyphSet = GlyphSet.KEYBOARD

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if current_device != event.device:
			current_device = event.device
			_detect_glyph_set()
	elif event is InputEventKey or event is InputEventMouseButton:
		if current_device != -1:
			current_device = -1
			glyph_set = GlyphSet.KEYBOARD

func glyph(action: String) -> String:
	return GLYPHS[glyph_set].get(action, action)

func _detect_glyph_set() -> void:
	var jname := Input.get_joy_name(current_device).to_lower()
	if jname.contains("sony") or jname.contains("playstation") \
			or jname.contains("dualshock") or jname.contains("dualsense"):
		glyph_set = GlyphSet.PLAYSTATION
	else:
		glyph_set = GlyphSet.XBOX
