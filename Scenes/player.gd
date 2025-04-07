extends CharacterBody3D

signal hp_changed
signal power_changed
signal possess_exit
signal restart


@export var MAX_HP = 3
@export var SPEED = 5.0
@export var ACCELERATION = 10.0
@export var JUMP_VELOCITY = 4.5
@export var GRAVITY = 9.8
@export var FALL_MULTIPLIER = 2.5  
@export var MOUSE_SENSITIVITY = 0.2
@export var CAMERA_KEY_SENSITIVITY = 1.5
@export var SPRINT_MULTIPLIER = 2.0

@onready var camera = $Camera3D
@onready var timeToLive = $timeToLive
@onready var postprocess_node = $Camera3D/PostProcessing
@onready var audio_player = $AudioStreamPlayer3D
@onready var animation_player = $"model/AnimationPlayer"

var fire_sound: AudioStream = preload("res://sound/fire.wav")
var reload_sound: AudioStream = preload("res://sound/reload.wav")
var walk_sound: AudioStream = preload("res://sound/walk.wav")



var HP = 0
var power = 4
var base_camera_position = Vector3.ZERO
var velocity_target = Vector3.ZERO
var postprocess_material: ShaderMaterial
var wave_active = false
var wave_timer = 0.0

const WAVE_DURATION = 2.0
var default_max_depth = 30.0 
var min_max_depth = 8.0
var current_max_depth = default_max_depth
var max_depth_decay_rate = 15.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	base_camera_position = camera.position
	_setup_postprocess_material()
	respawn()

func _setup_postprocess_material():
	if postprocess_node:
		if postprocess_node.has_method("get_active_material"):
			postprocess_material = postprocess_node.get_active_material(0) as ShaderMaterial
		elif postprocess_node.material_override:
			postprocess_material = postprocess_node.material_override as ShaderMaterial

func _input(event):
	handle_input(event)

func _physics_process(delta):
	if HP < 1:
		death()
		return
	
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(delta)
	_handle_camera_keys()
	_update_wave_effect(delta)
	_update_postprocess_material()
	
	move_and_slide()
	_update_animation()

func _apply_gravity(delta):
	if not is_on_floor():
		if velocity.y < 0:
			velocity.y -= GRAVITY * FALL_MULTIPLIER * delta
		else:
			velocity.y -= GRAVITY * delta

func _handle_jump():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

func _handle_movement(delta):
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
	
	print(velocity.x)
	print(velocity.y)
	if abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1:
		print("play")
		if not audio_player.playing:
			audio_player.stream = walk_sound
			audio_player.play()
	else:
		print("stop")

		audio_player.stop()
	
	if Input.is_action_just_pressed("shoot"):
		if power == 1:
			possess()
			power = 4
		else:
			shoot()
			power -= 1
		emit_signal("power_changed", power)
	
	if Input.is_action_just_pressed("possess"):
		#possess()
		pass

func _handle_camera_keys():
	var cam_x = float(Input.is_action_pressed("ui_right")) - float(Input.is_action_pressed("ui_left"))
	var cam_y = float(Input.is_action_pressed("ui_down")) - float(Input.is_action_pressed("ui_up"))
	rotation_degrees.y -= cam_x * CAMERA_KEY_SENSITIVITY
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x - cam_y * CAMERA_KEY_SENSITIVITY, -90, 90)

func _update_wave_effect(delta):
	var is_moving = (velocity_target.x != 0 or velocity_target.z != 0)
	
	if is_moving:
		wave_active = true
		wave_timer = 0.0
		current_max_depth = max(current_max_depth + max_depth_decay_rate * delta * 0.5, min_max_depth)
	else:
		if wave_active:
			wave_timer += delta
			if wave_timer >= WAVE_DURATION:
				wave_active = false
		current_max_depth = max(current_max_depth - max_depth_decay_rate * delta * 2, min_max_depth)

func _update_postprocess_material():
	if postprocess_material:
		var is_moving = (velocity_target.x != 0 or velocity_target.z != 0)
		postprocess_material.set_shader_parameter("is_moving", is_moving)
		postprocess_material.set_shader_parameter("wave_active", wave_active)
		postprocess_material.set_shader_parameter("max_depth", current_max_depth)

func handle_input(event):
	if event.is_action_pressed("exit"):
		#toggle_pause()
		pass
	elif event is InputEventMouseMotion and not get_tree().paused:
		handle_mouse_look(event)

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_mouse_look(event):
	rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x - event.relative.y * MOUSE_SENSITIVITY, -90, 90)

func shoot():
	audio_player.stream = fire_sound
	audio_player.play()

	
	var raycast = $Camera3D/RayCast3D
	var collider = raycast.get_collider()
	
	if collider:
		print(collider)
		if collider.is_in_group("enemy"):
			collider.changeHP(-1)
		else:
			print("мимо.")
			print(collider)
	
	_apply_recoil()

func _apply_recoil():
	var recoil_angle = 10.0 
	var recoil_offset = 0.5 
	var original_rot_x = camera.rotation_degrees.x
	var original_pos_z = camera.position.z
	
	camera.rotation_degrees.x = original_rot_x + recoil_angle
	camera.position.z = original_pos_z + recoil_offset
	
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "rotation_degrees:x", original_rot_x, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(camera, "position:z", original_pos_z, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func possess():
	var raycast = $Camera3D/RayCast3D
	var collider = raycast.get_collider()
	if not collider:
		return
	
	if collider.is_in_group("enemy") and collider.hp == 1:
		var temp_position = collider.position
		var temp_rotation = collider.rotation_degrees.y
		collider.position = position
		collider.rotation_degrees.y = rotation_degrees.y
		position = temp_position
		rotation_degrees.y = temp_rotation
		HP = 1
		timeToLive.stop()
		timeToLive.start()
		
	elif collider.is_in_group("exit"):
		emit_signal("possess_exit")
	
func death():
	print("You are dead!")
	velocity = Vector3.ZERO
	set_process(false)
	respawn()

func respawn():
	global_position = get_spawnpoint_position()
	changeHP(MAX_HP)
	set_process(true)
	camera.rotation_degrees = Vector3.ZERO
	rotation_degrees = Vector3.ZERO
	rotation_degrees.y = -180.0
	print("respawn")
	emit_signal("restart")


func get_spawnpoint_position() -> Vector3:
	var spawnpoints = get_tree().get_nodes_in_group("spawnpoint")
	if spawnpoints.size() > 0:
		return spawnpoints[0].global_position
	else:
		print("No spawnpoint found!")
		return Vector3.ZERO

func changeHP(amount):
	HP += amount
	if HP == 1:
		timeToLive.start()
	emit_signal("hp_changed", HP)
	if amount < 0:
		_player_hit()

func _player_hit():
	var recoil_angle_z = 10.0
	var original_rot_z = camera.rotation_degrees.z
	camera.rotation_degrees.z = original_rot_z + recoil_angle_z
	
	var tween = get_tree().create_tween()
	tween.tween_property(camera, "rotation_degrees:z", original_rot_z, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_time_to_live_timeout():
	death()

func toggle_pause():
	var tree = get_tree()
	tree.paused = not tree.paused

	if tree.paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#if has_node():
		#	$"/root/PauseMenu".show()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#if has_node():
		#	$"/root/PauseMenu".hide()
		
func _update_animation():
	if HP < 1:
		if animation_player.current_animation != "dead":
			animation_player.play("dead")
		return
 	
	if abs(velocity.x) > 0.1 or abs(velocity.z) > 0.1:
		if animation_player.current_animation != "walk":
			animation_player.play("walk")
