extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D

var target = null

@export var SPEED = 5.0
const JUMP_SPEED = 4.5
const JUMP_THRESHOLD = 1

func _ready():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("no player :(")
		return
	else:
		target = player

func _physics_process(delta):
	if target == null: return
	
	if navigation_agent.is_navigation_finished() or !navigation_agent.is_target_reachable():
		navigation_agent.target_position = target.global_position
		return
	
	var target_position = navigation_agent.get_next_path_position()
	var direction = (target_position - self.global_position).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	var can_move_forward = not test_move(transform, direction * 0.5)
	if not is_on_floor():
		velocity.y += self.get_gravity().y * delta
	else:
		velocity.y = 0
		if not can_move_forward:
			velocity.y = JUMP_SPEED

	move_and_slide()
