extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
@onready var raycast = $RayCast3D
@onready var fire_timeout = $fire_timeout
@onready var damage_timeout = $damage_timeout
@onready var tank_mesh = $"tank/Armature/Skeleton3D/Куб_002"
@export var hit_material: Material = load("res://shader/gray.tres")
@export var original_material: Material = load("res://shader/red.tres")

signal hp_changed
var target = null

@export var MAX_HP = 3
@export var MOVEMENT_SPEED = 2.0
@export var ROTATION_SPEED_DEFULT = 1
@export var JUMP_SPEED = 4.5
@export var bullet_scene: PackedScene = load("res://Scenes/bullet.tscn")

var HP = MAX_HP

const JUMP_THRESHOLD = 1

func _ready():
	find_player()
	fire_timeout.stop()
	tank_mesh.set_instance_shader_parameter("ShadowCastingSetting", 0)

func _physics_process(delta):
	if HP < 1:
		death()

	
	if target == null:
		return
	
	
	
	if not HP == 1:
		if should_update_path():
			update_path_to_target()
			return
	
		handle_movement(delta)
		handle_rotation_to_target()
		print(fire_timeout.time_left)
		if fire_timeout.is_stopped():
			shoot()
			fire_timeout.start()
		move_and_slide()

func shoot():
	print("shoot!")
	var collider = raycast.get_collider()
	if collider:
		print(collider)
		if collider.name == "player":
			collider.changeHP(-1)
		else:
			print("мимо.")

func find_player():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("no player :(")
	else:
		target = player

func should_update_path() -> bool:
	return navigation_agent.is_navigation_finished() or not navigation_agent.is_target_reachable()

func update_path_to_target():
	navigation_agent.target_position = target.global_position

func handle_movement(delta):
	var target_position = navigation_agent.get_next_path_position()
	var direction = (target_position - global_position).normalized()

	velocity.x = direction.x * MOVEMENT_SPEED
	velocity.z = direction.z * MOVEMENT_SPEED

	var can_move_forward = not test_move(transform, direction * 0.5)

	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0
		if not can_move_forward:
			velocity.y = JUMP_SPEED

func handle_rotation_to_target():
	var direction_vector = (target.position - position).normalized()
	var forward_vector = -global_transform.basis.z.normalized()
	var right_vector = -forward_vector.cross(Vector3.UP).normalized()
	
	var dot_product = direction_vector.dot(right_vector)
	var angle_to_target = forward_vector.angle_to(direction_vector)
	
	var rotation_speed = ROTATION_SPEED_DEFULT
	if angle_to_target > deg_to_rad(50):
		rotation_speed = ROTATION_SPEED_DEFULT * 3
	if angle_to_target < deg_to_rad(20):
		rotation_speed = ROTATION_SPEED_DEFULT / 1.5
	
	if dot_product > 0:
		rotation_degrees.y += rotation_speed
	elif dot_product < 0:
		rotation_degrees.y -= rotation_speed

func changeHP(ammount):
	HP += ammount
	emit_signal("hp_changed", HP)
	
	tank_mesh.material_override = hit_material
	
	
	damage_timeout.start()

func _on_damage_timeout_timeout():
	if not HP == 1:
		tank_mesh.material_override = original_material

func death():
	queue_free()
