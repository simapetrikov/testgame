extends Node

@export var enemy_scene: PackedScene = preload("res://Scenes/enemy.tscn")
@export var hit_material: Material = preload("res://shader/gray.tres")

var exit_is_ready = false

func _ready():
	spawnEnemies()

func _process(delta):
	if not exit_is_ready:
		check_exit_ready()

func spawnEnemies():
	var spawn_points = $world/enemySpawnPoints.get_children()
	for point in spawn_points:
		if point is Node3D:
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.global_transform = point.global_transform
			get_tree().current_scene.add_child(enemy_instance)
			enemy_instance.add_to_group("enemy")

func check_exit_ready():
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	if enemies.is_empty():
		_set_exit_ready()
		return

	for enemy in enemies:
		if enemy.hp > 1:
			return

	_set_exit_ready()

func _set_exit_ready():
	exit_is_ready = true
	var exit_nodes = get_tree().get_nodes_in_group("exit")
	for exit_node in exit_nodes:
		# Assuming each exit node has a MeshInstance3D as a child.
		if exit_node.has_node("MeshInstance3D"):
			var mesh_instance = exit_node.get_node("MeshInstance3D")
			mesh_instance.material_override = hit_material

func _on_player_possess_exit():
	print("asdfasdf")
	if exit_is_ready:
		print("level is done")
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_player_restart():
	var enemy_nodes = get_tree().get_nodes_in_group("enemy")
	for enemy_node in enemy_nodes:
		enemy_node.queue_free()
	spawnEnemies()
