class_name DashState
extends State

@export var forward_dash_velocity: float = 600.0
@export var backdash_velocity: float = 450.0 
@export var dash_duration: float = 0.2

var _timer: float = 0.0
var _is_backdash: bool = false

func enter(payload: Dictionary = {}) -> void:
	set_physics_process(true)
	_timer = 0.0
	
	# 👇 A MÁGICA DA OPÇÃO 2: Lemos a intenção diretamente do envelope (payload)!
	# Se a palavra "is_backdash" vier como verdadeira, ele vai para trás.
	# Se o envelope vier vazio ou falso, ele vai para a frente.
	_is_backdash = payload.get("is_backdash", false)
		
	var f_dir = facing.current_facing if facing else 1.0
	
	if _is_backdash:
		fighter.velocity.x = backdash_velocity * -f_dir
		if anim: anim.play("dash_backward")
	else:
		fighter.velocity.x = forward_dash_velocity * f_dir
		if anim: anim.play("dash_forward")

func physics_update(delta: float) -> void:
	_timer += delta
	if movement: movement.commit_movement()
	
	# Dash-To-Run: Cancela para Corrida apenas se for Dash para Frente
	if not _is_backdash and _timer >= 0.1:
		if input and input.get_movement_direction().x != 0:
			var current_dir = sign(input.get_movement_direction().x)
			var facing_dir = sign(facing.current_facing) if facing else 1.0
			if current_dir == facing_dir:
				transition_requested.emit("RunState", {})
				return

	if _timer >= dash_duration:
		_evaluate_exit()

func _evaluate_exit() -> void:
	# TRAVÃO INSTANTÂNEO (Zera a inércia, sem deslizar no gelo)
	fighter.velocity.x = 0
	
	if not input:
		transition_requested.emit("IdleState", {})
		return
		
	var dir = input.get_movement_direction()
	
	# Transições perfeitas e limpas após o Dash
	if dir.y > 0.5:
		transition_requested.emit("CrouchState", {})
	elif dir.x != 0:
		transition_requested.emit("WalkState", {})
	else:
		transition_requested.emit("IdleState", {})

func exit() -> void:
	set_physics_process(false)

func get_tags() -> Array[String]:
	return ["Grounded", "Dashing"]
