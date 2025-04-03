extends RigidBody3D

@export var speed: float = 50.0

func _ready():
	await get_tree().create_timer(10.0).timeout
	queue_free()
