class_name NormalMove
extends MoveComponent

# Configuração dos botões no Inspector
@export var punch_buttons: Array[String] = ["punch_light", "punch_heavy"]
@export var kick_buttons: Array[String] = ["kick_light", "kick_heavy"]

var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

func check_execution(buffer: InputBuffer) -> bool:
	var detected_button: String = ""
	var strength: String = ""
	var type: String = "" # "Punch" ou "Kick"

	# =========================================================
	# 1. IDENTIFICAÇÃO DO BOTÃO PREMIDO
	# =========================================================
	for btn in punch_buttons:
		if buffer.is_action_buffered(btn):
			detected_button = btn
			type = "Punch"
			strength = "Light" if "light" in btn else "Heavy"
			break
	
	if detected_button == "":
		for btn in kick_buttons:
			if buffer.is_action_buffered(btn):
				detected_button = btn
				type = "Kick"
				strength = "Light" if "light" in btn else "Heavy"
				break

	if detected_button == "":
		return false

	# =========================================================
	# 2. DETEÇÃO INDEPENDENTE DE POSTURA (SEM USAR TAGS)
	# =========================================================
	var posture = "stand"
	
	# Verificação 1: Está no ar? (Independente do estado da máquina)
	if buffer.fighter and not buffer.fighter.is_on_floor():
		posture = "air"
	
	# Verificação 2: Está a agachar? (Se estiver no chão)
	elif buffer.input:
		# Lemos a direção atual que o jogador está a pressionar
		var dir = buffer.input.get_movement_direction()
		
		# Se a direção Y for maior que 0.1, o jogador está a pressionar para baixo
		if dir.y > 0.1:
			posture = "crouch"
		else:
			posture = "stand"

	#print("🥊 GOLPE DETETADO: ", strength, " ", type, " | Postura Real: ", posture)

	# =========================================================
	# 3. MONTAGEM DO PAYLOAD
	# =========================================================
	buffer.consume_action(detected_button)
	
	payload_to_inject.clear()
	dynamic_target_state = target_state_name # Certifica-te que isto está preenchido no Inspector (ex: NormalAttack)
	
	# Cria o nome final do sub_state (ex: "LightPunch", "HeavyKick")
	payload_to_inject["sub_state"] = strength + type
	payload_to_inject["forced_posture"] = posture
	payload_to_inject["button_strength"] = strength.to_lower()
	print("🥊 [NormalMove] Detetou o botão! Estado gerado: [", dynamic_target_state, "]")
	return true
