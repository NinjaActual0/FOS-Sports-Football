extends Node
class_name GameManager

var game_mode: String = \"player\" # player, coach, sim
var simulation_speed: float = 1.0
var arcade_tuning: bool = false

func set_mode(mode: String) -> void:
	game_mode = mode
