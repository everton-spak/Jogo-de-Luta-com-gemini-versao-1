class_name WalkState
extends State

@export var forward_speed: float = 250.0
@export var backward_speed: float = 180.0
@export var acceleration: float = 2000.0

func enter(_payload: Dictionary = {}) -> void:
	_update_walk_animation()

func physics_update(delta: float) -> void:
	var dir = input.get_movement_direction()
	
	# Saídas do estado
	if dir.x == 0:
		transition_requested.emit("IdleState", {})
		return
	if dir.y > 0.5:
		transition_requested.emit("CrawlState", {})
		return
	if input.is_action_just_pressed("up"):
		transition_requested.emit("JumpState", {})
		return

	# Lógica de Movimento
	# Verifica se está andando para frente ou para trás em relação ao Facing
	var target_speed = forward_speed if dir.x == facing.current_facing else backward_speed
	
	movement.move_horizontal(dir.x, target_speed, acceleration, delta)
	movement.commit_movement()
	
	_update_walk_animation()

func _update_walk_animation() -> void:
	var dir_x = input.get_movement_direction().x
	if dir_x == facing.current_facing:
		anim.play("walk")
	else:
		anim.play("walk_back")
		
func get_tags() -> Array[String]:
	return ["Walking", "Cancellable"]
