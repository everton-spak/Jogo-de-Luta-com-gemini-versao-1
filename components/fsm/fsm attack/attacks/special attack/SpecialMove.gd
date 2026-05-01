class_name SpecialMove
extends MoveComponent

# Configuração da lista de golpes (Pode ser preenchida no Inspector)
@export var moves_list: Array[Dictionary] = [
	{
		"name": "Shoryuken",
		"motion": "623",       # Movimento em Z (Frente, Baixo, Diagonal)
		"type": "punch",      # Usa botões de soco
		"sub_state": "Shoryuken"
	},
	{
		"name": "Hadouken",
		"motion": "236",       # Meia-lua para frente
		"type": "punch",
		"sub_state": "Hadouken"
	},
	{
		"name": "Joudan",
		"motion": "236",       # Mesma meia-lua, mas para chute
		"type": "kick",
		"sub_state": "Joudan"
	},
	{
		"name": "Tatsumaki",
		"motion": "214",       # Meia-lua para trás
		"type": "kick",
		"sub_state": "Tatsumaki"
	}
]

@export var punch_buttons: Array[String] = ["punch_light", "punch_heavy"]
@export var kick_buttons: Array[String] = ["kick_light", "kick_heavy"]

# O estado pai na RootFSM que gerencia especiais
#@export var target_state_name: String = "SpecialAttack"

var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

func check_execution(buffer: InputBuffer) -> bool:
	# 1. Percorremos a lista na ordem de prioridade (Z primeiro, Meia-lua depois)
	for move in moves_list:
		if buffer.is_motion_buffered(move["motion"]):
			
			# 2. Verifica se o botão correspondente ao TIPO do golpe foi apertado
			var strength = _check_buttons_for_type(buffer, move["type"])
			
			if strength != "":
				# 3. Montagem do Payload para o SpecialAttackFSM
				payload_to_inject.clear()
				dynamic_target_state = target_state_name
				
				payload_to_inject["sub_state"] = move["sub_state"]
				payload_to_inject["strength"] = strength
				payload_to_inject["forced_posture"] = _get_current_posture(buffer)
				
				# Consome a sequência para não disparar dois golpes no mesmo frame
				buffer.consume_motion() 
				return true
				
	return false

# Função auxiliar para filtrar soco ou chute
func _check_buttons_for_type(buffer: InputBuffer, type: String) -> String:
	var buttons = punch_buttons if type == "punch" else kick_buttons
	
	for btn in buttons:
		if buffer.is_action_buffered(btn):
			buffer.consume_action(btn)
			return "light" if "light" in btn else "heavy"
	return ""

func _get_current_posture(buffer: InputBuffer) -> String:
	if not buffer.fighter.is_on_floor(): return "air"
	if buffer.input_provider.get_movement_direction().y > 0.5: return "crouch"
	return "stand"
