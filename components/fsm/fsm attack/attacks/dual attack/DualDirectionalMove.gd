class_name DualDirectionalMove
extends MoveComponent

# Configuração dos botões (Ex: ["punch_weak", "punch_strong"])
@export var button_pair: Array[String] = ["punch_weak", "punch_strong"]
@export var move_base_name: String = "DualPunch" # Nome base para o payload

# =========================================================
# CORREÇÃO: Variáveis declaradas para armazenar o envio
# =========================================================
var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}
#var target_state_name: String = "SpecialAttack" # Estado pai

func check_execution(buffer: InputBuffer) -> bool:
	# 1. VERIFICA SE OS DOIS BOTÕES FORAM APERTADOS (Macro)
	var pressed_count = 0
	for btn in button_pair:
		if buffer.is_action_buffered(btn):
			pressed_count += 1
	
	if pressed_count >= 2:
		# Consome os botões para não sair um soco normal junto
		for btn in button_pair:
			buffer.consume_action(btn)
		
		# =========================================================
		# 2. IDENTIFICAÇÃO DA DIREÇÃO (Notação 1-9)
		# =========================================================
		var input_dir = buffer.input_provider.get_movement_direction()
		var facing_comp = buffer.fighter.get_component("FacingComponent")
		var facing = facing_comp.current_facing if facing_comp else 1.0
		
		# Normalizamos a direção horizontal com base para onde o lutador olha
		var forward_back = input_dir.x * facing 
		
		var direction_code = "neutral"
		
		# Lógica de prioridade de direção:
		if input_dir.y > 0.5:
			if forward_back > 0.5:
				direction_code = "down_forward" # Diagonal Frente-Baixo (3)
			else:
				direction_code = "down"         # Baixo (2)
		elif forward_back > 0.5:
			direction_code = "forward"          # Frente (6)
			
		# =========================================================
		# 3. MONTAGEM DO PAYLOAD
		# =========================================================
		payload_to_inject.clear()
		dynamic_target_state = target_state_name 
		
		payload_to_inject["sub_state"] = move_base_name
		payload_to_inject["direction_tag"] = direction_code
		
		# Se o seu InputBuffer.gd estiver a ler variáveis diretamente do nó (como sub_state),
		# podemos declará-las no próprio nó por segurança:
		if "sub_state" in self:
			self.set("sub_state", move_base_name)
		
		return true
		
	return false
