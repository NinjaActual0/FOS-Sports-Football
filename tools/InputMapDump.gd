extends SceneTree
## Dev utility: dump the resolved input map, so we can confirm the left stick
## is actually bound to the move actions (not just the d-pad).
## Usage: godot --path . --script res://tools/InputMapDump.gd

var _frames := 0

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 10:
		return false

	print("display_driver: ", DisplayServer.get_name())
	var pads := Input.get_connected_joypads()
	print("joypads: ", pads.size(), "  first: ", Input.get_joy_name(pads[0]) if pads.size() > 0 else "none")

	for action in ["move_forward", "move_backward", "move_left", "move_right", "sprint", "spin"]:
		print("%s:" % action)
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadMotion:
				print("   JOY AXIS %d at %+.1f" % [ev.axis, ev.axis_value])
			elif ev is InputEventJoypadButton:
				print("   JOY BTN %d" % ev.button_index)
			elif ev is InputEventKey:
				print("   KEY %s" % OS.get_keycode_string(ev.physical_keycode))
	print("input_map_dump_done")
	return true
