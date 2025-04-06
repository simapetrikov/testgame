extends CharacterBody3D

signal hp_changed

@export var MAX_HP = 3
@export var SPEED = 5.0
@export var ACCELERATION = 10.0
@export var JUMP_VELOCITY = 4.5
@export var GRAVITY = 9.8
@export var FALL_MULTIPLIER = 2.5  
@export var MOUSE_SENSITIVITY = 0.2
@export var CAMERA_KEY_SENSITIVITY = 1.5
@export var SPRINT_MULTIPLIER = 2.0
@export var BOB_SPEED = 8.0 
@export var BOB_AMOUNT = 0.08 
@export var bullet_scene: PackedScene = load("res://Scenes/bullet.tscn")

@onready var Camera = $Camera3D
@onready var timeToLive = $timeToLive

var HP = MAX_HP

var base_camera_position = Vector3.ZERO
var velocity_target = Vector3.ZERO
var head_bob_time = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_camera_position = Camera.position
	

func _input(event):
	handle_input(event)

func _physics_process(delta):
	if HP < 1 :
		death()
	
	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	handle_camera_keys()
	# apply_head_bob(delta, direction) 

	move_and_slide()


func handle_input(event):
	if event.is_action_pressed("exit"):
		toggle_mouse_mode()
	elif event is InputEventMouseMotion:
		handle_mouse_look(event)

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_mouse_look(event):
	rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
	Camera.rotation_degrees.x = clamp(Camera.rotation_degrees.x - event.relative.y * MOUSE_SENSITIVITY, -90, 90)



func apply_gravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y -= GRAVITY * FALL_MULTIPLIER * delta
		else:
			velocity.y -= GRAVITY * delta

func handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_foward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var current_speed = SPEED
	if Input.is_action_pressed("sprint"):
		current_speed *= SPRINT_MULTIPLIER

	if direction:
		velocity_target.x = direction.x * current_speed
		velocity_target.z = direction.z * current_speed
	else:
		velocity_target.x = 0
		velocity_target.z = 0

	velocity.x = lerp(velocity.x, velocity_target.x, ACCELERATION * delta)
	velocity.z = lerp(velocity.z, velocity_target.z, ACCELERATION * delta)

	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	if Input.is_action_just_pressed("possess"):
		possess()


func handle_camera_keys():
	var cam_x = float(Input.is_action_pressed("ui_right")) - float(Input.is_action_pressed("ui_left"))
	var cam_y = float(Input.is_action_pressed("ui_down")) - float(Input.is_action_pressed("ui_up"))

	rotation_degrees.y -= cam_x * CAMERA_KEY_SENSITIVITY
	Camera.rotation_degrees.x = clamp(Camera.rotation_degrees.x - cam_y * CAMERA_KEY_SENSITIVITY, -90, 90)

func shoot():
	var raycast = $Camera3D/RayCast3D
	var collider = raycast.get_collider()
	
	if collider:
		if collider.is_in_group("enemy"):
			collider.changeHP(-1)
		else:
			print("мимо.")
	
	var recoil_angle = 10.0 
	var recoil_offset = 0.5 
	
	var original_rot_x = Camera.rotation_degrees.x
	var original_pos_z = Camera.position.z
	
	Camera.rotation_degrees.x = original_rot_x + recoil_angle
	Camera.position.z = original_pos_z + recoil_offset
	
	var tween = get_tree().create_tween()
	tween.tween_property(Camera, "rotation_degrees:x", original_rot_x, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(Camera, "position:z", original_pos_z, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)




func possess():
	var raycast = $Camera3D/RayCast3D
	var collider = raycast.get_collider()
	
	if collider:
		if collider.is_in_group("enemy"):
			if collider.HP == 1:
				var temp_position = collider.position
				var temp_rotation = collider.rotation_degrees.y
				collider.position = position
				collider.rotation_degrees.y = rotation_degrees.y
				position = temp_position
				rotation_degrees.y = temp_rotation
				HP = 1
				timeToLive.stop()
				timeToLive.start()
				
			else:
				print("мимо.")




func death():
	print("You are dead!")
	
	velocity = Vector3.ZERO
	set_process(false)
	respawn()

func respawn():
	global_position = get_spawnpoint_position()
	changeHP(MAX_HP)

	set_process(true)
	
func get_spawnpoint_position() -> Vector3:
	var spawnpoint = get_tree().get_nodes_in_group("spawnpoint").front()
	
	if spawnpoint:
		return spawnpoint.global_position 
	else:
		print("No spawnpoint found!")
		return Vector3.ZERO

func changeHP(ammount):
	HP += ammount
	if HP == 1:
		timeToLive.start()
	emit_signal("hp_changed", HP)
	
	if ammount < 0:
		player_hit()
	
func player_hit():
	var recoil_angle_z = 10.0
	var original_rot_z = Camera.rotation_degrees.z
	
	Camera.rotation_degrees.z = original_rot_z + recoil_angle_z
	
	var tween = get_tree().create_tween()
	tween.tween_property(Camera, "rotation_degrees:z", original_rot_z, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_time_to_live_timeout():
	death()
