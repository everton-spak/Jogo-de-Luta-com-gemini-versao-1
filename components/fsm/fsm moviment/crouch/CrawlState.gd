class_name CrawlState
extends State

@export var crawl_speed: float = 120.0

func enter(_payload: Dictionary = {}) -> void:
	anim.play("crawl")

func physics_update(delta: float) -> void:
	var dir = input.get_movement_direction()
	
	# Se parar de mover pro lado, volta pro "CrouchIdle" (que agora chamaremos de CrouchIdleState)
	if dir.x == 0:
		transition_requested.emit("CrouchIdleState") # Nome do sub-estado
		return
		
	if input.is_action_just_pressed("up") or dir.y < -0.5:
		transition_requested.emit("JumpState", {})
		return
	movement.move_horizontal(dir.x, crawl_speed, 1500.0, delta)
	movement.commit_movement()
	
func get_tags() -> Array[String]:
	return ["Walking", "Cancellable"]
