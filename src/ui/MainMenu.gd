extends Control

func _ready() -> void:
	/Play.pressed.connect(_on_play)
	/CoachMode.pressed.connect(_on_coach)
	/SimGame.pressed.connect(_on_sim)
	/Quit.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file(\"res://src/core/GreyboxField.tscn\")

func _on_coach() -> void:
	GameManager.set_mode(\"coach\")
	get_tree().change_scene_to_file(\"res://src/core/GreyboxField.tscn\")

func _on_sim() -> void:
	GameManager.set_mode(\"sim\")
	get_tree().change_scene_to_file(\"res://src/core/GreyboxField.tscn\")

func _on_quit() -> void:
	get_tree().quit()
