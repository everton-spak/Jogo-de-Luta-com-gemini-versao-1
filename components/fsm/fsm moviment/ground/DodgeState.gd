class_name DodgeState
extends State

@export var dodge_velocity: float = 500.0
@export var invincibility_duration: float = 0.25
@export var total_duration: float = 0.4
@export var friction_on_recovery: float = 3000.0

var _timer: float = 0.0
var _is_invincible: bool = false

func enter(_payload: Dictionary = {}) -> void:
	_timer = 0.0
	_is_invincible = true
	
	# O impulso inicial da esquiva
	fighter.velocity.x = dodge_velocity * facing.current_facing
	
	if anim:
		anim.play("dodge")
	
	# Desativa a colisão com o oponente (Proximity/Hitbox) se necessário
	if hitbox: hitbox.disable_box()

func physics_update(delta: float) -> void:
	_timer += delta
	
	# Fase 1: Ativa (Invencível e Rápida)
	if _timer < invincibility_duration:
		movement.commit_movement()
	
	# Fase 2: Recuperação (Vulnerável e Freando)
	else:
		if _is_invincible:
			_is_invincible = false
			
		
		movement.apply_friction(friction_on_recovery, delta)
		movement.commit_movement()

	# Fim do Estado
	if _timer >= total_duration:
		_evaluate_exit()

func _evaluate_exit() -> void:
	var dir = input.get_movement_direction()
	if dir.y > 0.5:
		transition_requested.emit("CrouchState", {})
	elif dir.x != 0:
		transition_requested.emit("WalkState", {})
	else:
		transition_requested.emit("IdleState", {})

func exit() -> void:
	_is_invincible = false
	
func get_tags() -> Array[String]:
	return ["Dodging", "Grounded"]
	
