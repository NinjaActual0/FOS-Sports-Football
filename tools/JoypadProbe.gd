extends SceneTree
## Dev utility: print every gamepad Godot can see, then exit.
## Must run WITHOUT --headless, since the headless display driver does not
## initialise the joypad backend.
## Usage: godot --path . --script res://tools/JoypadProbe.gd

var _frames := 0
var _reported := false

func _initialize() -> void:
	print("display_driver: ", DisplayServer.get_name())
	print("spawned_window: ", DisplayServer.window_get_mode() if DisplayServer.get_name() != "headless" else -1)

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 20:
		return false
	if not _reported:
		_reported = true
		var pads := Input.get_connected_joypads()
		print("godot_joypads: ", pads.size())
		for id in pads:
			print("  id=", id,
				" name='", Input.get_joy_name(id), "'",
				" guid='", Input.get_joy_guid(id), "'",
				" mapped=", Input.is_joy_known(id),
				" info=", Input.get_joy_info(id))
		print("joypad_probe_done")
	return true
