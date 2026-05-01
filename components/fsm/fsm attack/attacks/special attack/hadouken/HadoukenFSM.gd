class_name HadoukenFSM
extends StateMachine

func _on_enter(payload: Dictionary = {}) -> void:
	# Por padrão, assumimos a versão em pé
	var target_sub_state = "StandHadouken"
	
	# =========================================================
	# 1. PRIORIDADE MÁXIMA: FÍSICA (O lutador está no ar?)
	# =========================================================
	if not fighter.is_on_floor():
		target_sub_state = "AirHadouken"
		
	# =========================================================
	# 2. PRIORIDADE MÉDIA: PAYLOAD (O InputBuffer forçou uma postura?)
	# =========================================================
	elif payload.has("forced_posture"):
		target_sub_state = payload.get("forced_posture").capitalize() + "Hadouken"
		
	# =========================================================
	# 3. PRIORIDADE BAIXA: LEITURA DIRETA (Fallback)
	# =========================================================
	else:
		var input = fighter.get_component("Input")
		if input and input.is_action_pressed("crouch"):
			target_sub_state = "CrouchHadouken"
			
	# 👇 MELHORIA: Como sou a FSM pai destes golpes, mudo o estado diretamente!
	change_state(target_sub_state, payload)
