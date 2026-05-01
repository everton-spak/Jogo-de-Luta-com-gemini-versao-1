class_name ChargeMove
extends MoveComponent

# Configuração da lista de golpes de carga no Inspector
@export var charge_moves: Array[Dictionary] = [
	{
		"name": "SonicBoom",
		"charge_dir": "B",       # Trás (Back)
		"min_ms": 800.0,         # Tempo de carga (0.8s)
		"release": "F",          # Soltar para Frente (Forward)
		"button_type": "punch",
		"sub_state": "SonicBoom"
	},
	{
		"name": "FlashKick",
		"charge_dir": "D",       # Baixo (Down)
		"min_ms": 700.0,         # Tempo de carga (0.7s)
		"release": "U",          # Soltar para Cima (Up)
		"button_type": "kick",
		"sub_state": "FlashKick"
	}
]

# Variáveis internas para o payload
var dynamic_target_state: String = "SpecialAttack"
var payload_to_inject: Dictionary = {}

func check_execution(buffer: InputBuffer) -> bool:
	for move in charge_moves:
		# 1. VERIFICA SE A CARGA ESTÁ PRONTA
		# Usamos a função que já existe no seu InputBuffer.gd
		if buffer.is_charge_ready(move["charge_dir"], move["min_ms"]):
			
			# 2. VERIFICA SE O COMANDO DE SOLTAR (RELEASE) FOI FEITO
			# Como o seu buffer armazena direções como "motion", verificamos o histórico recente
			if _is_motion_in_buffer(buffer, move["release"]):
				
				# 3. VERIFICA SE O BOTÃO FOI APERTADO
				var strength = _check_attack_buttons(buffer, move["button_type"])
				
				if strength != "":
					# SUCESSO! Limpamos a carga e preparamos o envio
					buffer.consume_charge(move["charge_dir"])
					
					payload_to_inject.clear()
					payload_to_inject["sub_state"] = move["sub_state"]
					payload_to_inject["strength"] = strength
					
					# Define a postura (Carga costuma ser Stand ou Crouch)
					payload_to_inject["forced_posture"] = "stand" if buffer.fighter.is_on_floor() else "air"
					
					return true
					
	return false

# Função auxiliar para verificar se a direção de "soltar" está no buffer recente
func _is_motion_in_buffer(buffer: InputBuffer, direction: String) -> bool:
	return buffer.is_action_buffered(direction)

# Filtra botões baseando-se no tipo (punch/kick) e nas constantes do seu buffer
func _check_attack_buttons(buffer: InputBuffer, type: String) -> String:
	var strengths = ["heavy", "light"]
	for s in strengths:
		var action_name = type + "_" + s # Ex: punch_strong, kick_weak
		if buffer.is_action_buffered(action_name):
			buffer.consume_action(action_name)
			return s
	return ""
