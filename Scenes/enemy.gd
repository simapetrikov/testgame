extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var raycast = $RayCast3D
@onready var fire_timer = $fire_timeout
@onready var damage_timer = $damage_timeout
@onready var model_mesh = $"model/Armature/Skeleton3D/Куб_002"
@onready var animation_player = $"model/AnimationPlayer"
@onready var audio_player = $AudioStreamPlayer3D
var fire_sound: AudioStream = preload("res://sound/fire.wav")
var reload_sound: AudioStream = preload("res://sound/reload.wav")
var walk_sound: AudioStream = preload("res://sound/walk.wav")

@export var hit_material: Material = preload("res://shader/gray.tres")
@export var original_material: Material = preload("res://shader/red.tres")

@export var MAX_HP := 3
@export var MOVE_SPEED := 2.0
@export var ROTATE_SPEED := 1.0
@export var JUMP_SPEED := 4.5
@export var SEARCH_RADIUS := 10.0 



const JUMP_THRESHOLD := 1.0

signal hp_changed

var target: Node3D = null
var hp: int = MAX_HP
var is_moving: bool = true

func _ready():
	target = get_tree().get_first_node_in_group("player")
	if target == null:
		push_error("No player found.")
	
	fire_timer.stop()
	model_mesh.set_instance_shader_parameter("ShadowCastingSetting", 0)

	nav_agent.radius = 1
	nav_agent.set_debug_enabled(true)
	
	animation_player.speed_scale = 0.5
	animation_player.play("idle")
	

func _physics_process(delta):
	if hp <= 0:
		_die()
		return
	
	_apply_gravity(delta)

	if target and global_position.distance_to(target.global_position) < SEARCH_RADIUS:
		if hp > 1:
			if _needs_path_update():
				nav_agent.target_position = target.global_position
			_rotate_towards_target()
			
			if fire_timer.is_stopped():
				_shoot()
				fire_timer.start()
				audio_player.stream = reload_sound
				audio_player.play()
		
		_move_towards_target(delta)
	
	move_and_slide()
	
	_update_animation()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0

func _move_towards_target(delta):
	if not is_moving:
		if audio_player.playing and audio_player.stream == walk_sound:
			audio_player.stop()
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()

	velocity.x = direction.x * MOVE_SPEED
	velocity.z = direction.z * MOVE_SPEED

	if not audio_player.playing:
		audio_player.stream = walk_sound
		audio_player.play()

	var blocked = test_move(transform, direction * 0.5)

	if is_on_floor() and blocked:
		velocity.y = JUMP_SPEED


func _rotate_towards_target():
	var dir = (target.global_position - global_position).normalized()
	var forward = -global_transform.basis.z.normalized()
	var right = forward.cross(Vector3.UP).normalized()

	var dot = dir.dot(right)
	var angle = forward.angle_to(dir)
	
	var speed = ROTATE_SPEED
	if angle > deg_to_rad(50): 
		speed *= 3
	elif angle < deg_to_rad(20): 
		speed /= 1.5

	rotation_degrees.y += -speed if dot > 0 else speed

func _shoot():
	animation_player.play("attack")
	audio_player.stream = fire_sound
	audio_player.play()
	
	var collider = raycast.get_collider()
	if collider and collider.name == "player":
		collider.changeHP(-1)
	else:
		print("мимо")

func _needs_path_update() -> bool:
	return nav_agent.is_navigation_finished() or not nav_agent.is_target_reachable()

func changeHP(amount: int):
	hp += amount
	emit_signal("hp_changed", hp)

	if hp == 1:
		is_moving = false
		velocity = Vector3.ZERO
	
	model_mesh.material_override = hit_material
	damage_timer.start()

func _on_damage_timeout_timeout():
	if hp > 1:
		model_mesh.material_override = original_material

func _die():
	if animation_player.current_animation != "dead":
		animation_player.speed_scale = 0.20
		animation_player.play("dead")
		await get_tree().create_timer(1).timeout
		queue_free()
func _update_animation():
	if hp <= 0:
		return
	if hp == 1:
		animation_player.pause()
	elif not is_moving:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
	elif target and global_position.distance_to(target.global_position) < SEARCH_RADIUS:
		if animation_player.current_animation != "chase":
			animation_player.play("chase")
	else:
		if animation_player.current_animation != "idle":
			animation_player.play("idle")
