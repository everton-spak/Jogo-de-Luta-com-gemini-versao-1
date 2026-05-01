class_name TatsumakiFSM
extends StateMachine

func _on_enter(payload: Dictionary = {}) -> void:
	# O estado padrão é o Tatsumaki em pé
	var target_sub_state = "StandTatsumaki"
	
	# =========================================================
	# 1. PRIORIDADE FÍSICA (Obrigatório)
	# =========================================================
	# Se o lutador já está no ar, ignora os comandos de chão e ativa o Hover!
	if not fighter.is_on_floor():
		target_sub_state = "AirTatsumaki"
		
	# =========================================================
	# 2. PRIORIDADE DE PAYLOAD ("Smart Input")
	# =========================================================
	# O TatsumakiMove.gd leu que o jogador terminou a meia-lua para trás
	# a segurar para baixo? Se sim, injetou "crouch" aqui!
	elif payload.has("forced_posture"):
		target_sub_state = payload.get("forced_posture").capitalize() + "Tatsumaki"
		
	# =========================================================
	# 3. FALLBACK (Leitura ao vivo do direcional)
	# =========================================================
	# Caso o comando tenha vindo de outra fonte (ex: um botão de macro)
	else:
		var input = fighter.get_component("Input")
		if input and input.is_action_pressed("crouch"):
			target_sub_state = "CrouchTatsumaki"
			
	# Repassa a ordem instantaneamente para o executor!
	transition_requested.emit(target_sub_state, payload)
