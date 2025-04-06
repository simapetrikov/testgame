extends Control


func _ready():
	setHP()


func _process(delta):
	$VBoxContainer/timeLeft.text = str(int($"../world/player".timeToLive.time_left))


func _on_player_hp_changed(new_hp):
	$VBoxContainer/HP.text = str(new_hp)




func setHP():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("no player :(")
	else:
		player.changeHP(0)
