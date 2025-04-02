extends CharacterBody3D

@onready var navigation_agent = $NavigationAgent3D
var target = null

@export var SPEED = 2.0
const JUMP_VELOCITY = 4.5

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
	
	velocity = (navigation_agent.get_next_path_position() - 
		self.global_position).normalized() * SPEED
	
	velocity.y = self.velocity.y + self.get_gravity().y * delta
	velocity.y = 0

	move_and_slide() 
