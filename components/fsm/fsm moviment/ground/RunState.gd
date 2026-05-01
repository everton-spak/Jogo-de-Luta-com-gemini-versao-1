class_name RunState
extends State

@export var run_velocity: float = 700.0
var _run_dir: float = 1.0

func enter(_payload: Dictionary = {}) -> void:
	# Descobre para que lado o jogador está a correr
	if input and input.get_movement_direction().x != 0:
		_run_dir = sign(input.get_movement_direction().x)
	else:
		_run_dir = facing.current_facing if facing else 1.0

	# Toca a animação da corrida
	if anim:
		if anim.sprite.sprite_frames.has_animation("run"):
			anim.play("run")
		

func physics_update(_delta: float) -> void:
	fighter.velocity.x = run_velocity * _run_dir
	if movement: movement.commit_movement()
		
	# Para de correr instantaneamente se o jogador soltar o botão ou apertar para trás
	if input:
		var current_dir = input.get_movement_direction().x
		if current_dir == 0.0 or sign(current_dir) != sign(_run_dir):
			_stop_running()

func _stop_running() -> void:
	var dir = input.get_movement_direction() if input else Vector2.ZERO
	if dir.y > 0.5:
		transition_requested.emit("CrouchState", {})
	else:
		transition_requested.emit("IdleState", {})
		
func get_tags() -> Array[String]:
	return ["Grounded", "Running"]
