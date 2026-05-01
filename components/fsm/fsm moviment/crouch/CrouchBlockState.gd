class_name CrouchBlockState
extends State

func enter(payload: Dictionary = {}) -> void:
	anim.play("block_crouch")
	var knockback = payload.get("knockback", 0.0)
	# Empurra para trás se for um bloqueio de impacto
	movement.apply_impulse(Vector2(-facing.current_facing * knockback, 0))

func physics_update(delta: float) -> void:
	movement.apply_friction(2500.0, delta)
	movement.commit_movement()
	
	# Se o tempo de blockstun acabar (precisaria de um timer aqui), volta pro CrouchIdle
	# Ou se o jogador soltar a defesa, o GroundState detecta e transita.
	
	
func get_tags() -> Array[String]:
	return ["Blocking", "Blockstun"]
