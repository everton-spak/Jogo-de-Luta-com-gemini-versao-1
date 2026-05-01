class_name AllTypeMove
extends MoveComponent

# Configuração da lista de golpes (Pode ser editada no Inspector)
@export var moves_list: Array[Dictionary] = [
	# --- GOLPES DE CARGA ---
	{
		"name": "SonicBoom",
		"is_charge": true,
		"charge_dir": "B",       # Carga para Trás 
		"min_ms": 800.0,         # Milissegundos necessários 
		"release": "F",          # Comando de liberação: Frente 
		"type": "punch",
		"sub_state": "SonicBoom"
	},
	{
		"name": "FlashKick",
		"is_charge": true,
		"charge_dir": "D",       # Carga para Baixo 
		"min_ms": 700.0,
		"release": "U",          # Comando de liberação: Cima 
		"type": "kick",
		"sub_state": "FlashKick"
	},
	# --- GOLPES DE MOVIMENTO (MEIA-LUA/Z) ---
	{
		"name": "Shoryuken",
		"is_charge": false,
		"sequence": ["F", "D", "DF"], # Movimento em Z 
		"type": "punch",
		"sub_state": "Shoryuken"
	},
	{
		"name": "Hadouken",
		"is_charge": false,
		"sequence": ["D", "DF", "F"], # Meia-lua frente 
		"type": "punch",
		"sub_state": "Hadouken"
	}
]

# Variáveis que o InputBuffer.gd lerá para montar o comando final 
var sub_state: String = ""
var forced_posture: String = ""

func check_execution(buffer: InputBuffer) -> bool:
	for move in moves_list:
		# 1. LÓGICA PARA GOLPES DE CARGA
		if move.get("is_charge", false):
			# Usa a função nativa do seu buffer para ver se a carga está pronta 
			if buffer.is_charge_ready(move["charge_dir"], move["min_ms"]):
				# Verifica se a direção de liberação foi apertada recentemente 
				if buffer.is_action_buffered(move["release"]):
					var strength = _check_buttons(buffer, move["type"])
					if strength != "":
						# Sucesso: Limpa a carga e o buffer de movimento 
						buffer.consume_charge(move["charge_dir"])
						buffer.consume_action(move["release"])
						return _prepare_payload(move, strength, buffer)
						
		# 2. LÓGICA PARA GOLPES DE MOVIMENTO (SEQUÊNCIAS)
		else:
			# Usa a função do seu buffer para validar a sequência de strings 
			if buffer.is_sequence_buffered(move["sequence"]):
				var strength = _check_buttons(buffer, move["type"])
				if strength != "":
					buffer.consume_sequence() # Limpa o buffer para evitar repetições 
					return _prepare_payload(move, strength, buffer)
					
	return false

# Filtra se o botão apertado condiz com o tipo (Punch ou Kick) usando os ACTION_BUTTONS 
func _check_buttons(buffer: InputBuffer, type: String) -> String:
	# Mapeia para as strings exatas definidas no seu InputBuffer.gd 
	var strengths = ["heavy", "light"]
	for s in strengths:
		var action_name = type + "_" + s
		if buffer.is_action_buffered(action_name):
			buffer.consume_action(action_name) # Consome o botão 
			return s
	return ""

func _prepare_payload(move: Dictionary, strength: String, buffer: InputBuffer) -> bool:
	# Define as variáveis que o seu InputBuffer.gd utiliza no return 
	self.sub_state = move["sub_state"]
	self.target_state_name = "SpecialAttack"
	
	# Detecta a postura atual para enviar ao estado de ataque 
	var dir = buffer.input.get_movement_direction()
	if not buffer.fighter.is_on_floor(): 
		self.forced_posture = "air"
	elif dir.y > 0.5: 
		self.forced_posture = "crouch"
	else: 
		self.forced_posture = "stand"
		
	return true
