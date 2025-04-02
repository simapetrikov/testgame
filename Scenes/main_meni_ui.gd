extends Control

func _ready() -> void:
	print("Howdy:3")

func start_game() -> void:
	get_tree().change_scene_to_file("res://Scenes/level.tscn")



func _on_button_pressed():
	start_game()
