extends CharacterBody3D

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

@export var bullet_scene: PackedScene  = load("res://Scenes/bullet.tscn")

@onready var Camera = $Camera3D

var base_camera_position = Vector3.ZERO
var velocity_target = Vector3.ZERO
var head_bob_time = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_camera_position = Camera.position

func _input(event):
	if event.is_action_pressed("exit"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		Camera.rotation_degrees.x = clamp(Camera.rotation_degrees.x - event.relative.y * MOUSE_SENSITIVITY, -90, 90)

func _physics_process(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y -= GRAVITY * FALL_MULTIPLIER * delta
		else:
			velocity.y -= GRAVITY * delta
	
	if Input.is_action_just_pressed("shoot"):
		spawn_bullet()

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
	
	#apply_head_bob(delta, direction)

	var cam_x = (float(Input.is_action_pressed("ui_right")) - float(Input.is_action_pressed("ui_left"))) * CAMERA_KEY_SENSITIVITY
	var cam_y = (float(Input.is_action_pressed("ui_down")) - float(Input.is_action_pressed("ui_up"))) * CAMERA_KEY_SENSITIVITY
	rotation_degrees.y -= cam_x
	Camera.rotation_degrees.x = clamp(Camera.rotation_degrees.x - cam_y, -90, 90)

	move_and_slide()

func apply_head_bob(delta, direction):
	if direction.length() > 0 and is_on_floor():
		head_bob_time += delta * BOB_SPEED * 0.5
		var t = head_bob_time
		var offset = Vector3(
			sin(t) * (BOB_AMOUNT * 0.3),
			sin(2 * t) * (BOB_AMOUNT * 0.5),
			0
		)
		$Camera3D.position = base_camera_position + offset
	else:
		head_bob_time = 0
		Camera.position = base_camera_position



func spawn_bullet():
	var bullet = bullet_scene.instantiate() as RigidBody3D
	
	var player_transform = Camera.global_transform
	var forward_offset = -player_transform.basis.z.normalized() * 2.0

	bullet.global_transform.origin = player_transform.origin + forward_offset
	get_tree().get_current_scene().add_child(bullet)
	
	bullet.apply_impulse(-player_transform.basis.z.normalized() * bullet.speed)
