class_name GroundState
extends StateMachine # <-- Herda da FSM para gerir sub-estados

func _on_enter(_payload: Dictionary = {}) -> void:
	# Esta função roda ASSIM QUE o personagem toca o chão
	# Vindo de um FallState, por exemplo.
	if anim:
		# Você pode ter uma animação de "Landing" genérica aqui
		pass
		
	# Sempre que o personagem volta a pisar no chão de forma neutra (Idle/Walk),
	# nós garantimos que qualquer combo que ele estava a sofrer é limpo!
	if combo_scaling:
		combo_scaling.reset_combo()

func _on_physics_update(delta: float) -> void:
	# ==========================================
	# 1. REGRA GLOBAL: SAÍDA DO CHÃO
	# ==========================================
	# Se em qualquer frame de qualquer estado de chão o boneco não estiver no piso:
	if not fighter.is_on_floor():
		# Passa a "batata quente" para a StateMachine superior (Root)
		transition_requested.emit("AirState", {})
		return

	# ==========================================
	# 2. FÍSICA GLOBAL DE SOLO
	# ==========================================
	# Aplica gravidade para manter o boneco colado ao chão (importante para rampas)
	if movement:
		movement.apply_gravity(delta)
		# Note que não chamamos commit_movement() aqui, 
		# deixamos o sub-estado (Idle/Walk) decidir quando aplicar o movimento final.

	# ==========================================
	# 3. VERIFICAÇÃO DE DEFESA (BLOCK)
	# ==========================================
	# Se o jogador estiver segurando para trás e houver um ataque na ProximityBox
	_check_block_input()

func _check_block_input() -> void:
	if not input or not proximity: return
	
	# Se existe um inimigo atacando por perto e o jogador segura para trás
	if proximity.is_target_near:
		var dir = input.get_movement_direction().x
		if dir == -facing.current_facing:
			# Se o sub-estado atual não for defesa, mude para defesa!
			if current_state and not "Blocking" in current_state.get_tags():
				change_state("StandBlockState")


func get_machine_tags() -> Array[String]:
	return ["Grounded"]
