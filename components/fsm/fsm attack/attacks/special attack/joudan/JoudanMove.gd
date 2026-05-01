class_name JoudanMove
extends MoveComponent

# =========================================================
# AS DUAS POSSIBILIDADES DE COMANDO
# =========================================================
@export var sequence_heavy: Array[String] = ["D", "DF", "F", "kick_strong"]
@export var sequence_light: Array[String] = ["D", "DF", "F", "kick_light"]

#@export var target_state_name: String = "SpecialAttack"
@export var sub_state: String = "Joudan"

var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

# Variáveis internas para manter a memória da carga
var _forced_posture: String = "stand"
var _is_charging_motion: bool = false 
var _active_charge_btn: String = "" # Guarda se foi kick_light ou kick_strong
var _active_strength: String = ""   # Guarda "light" ou "heavy"

func check_execution(buffer: InputBuffer) -> bool:
	var mechanic = buffer.fighter.get_component("SpecialMechanicComponent")
	if not mechanic: return false
	
	# =========================================================
	# FASE B: O JOGADOR JÁ FEZ A MEIA-LUA E ESTÁ A SEGURAR O CHUTE
	# =========================================================
	if _is_charging_motion:
		var delta = buffer.get_physics_process_delta_time()
		
		# Avalia o tempo de carga do chute específico que iniciou o golpe
		var result = mechanic.process_charge(_active_charge_btn, delta)
		var status = result.get("status", "inactive")
		
		# 1. Continua a segurar a perna no ar? Esperamos.
		if status == "charging":
			return false 
			
		# 2. Soltou o botão ou ativou uma Macro! Vamos processar.
		_is_charging_motion = false
		payload_to_inject.clear()
		
		match status:
			# CENÁRIO 1: Soltou o botão para desferir o chute
			"normal", "strong", "super":
				dynamic_target_state = target_state_name
				payload_to_inject["sub_state"] = sub_state
				payload_to_inject["forced_posture"] = _forced_posture 
				
				# Envia a força da carga (para aumentar dano e mudar animação)
				payload_to_inject["charge_level"] = status
				payload_to_inject["multiplier"] = result.get("multiplier", 1.0) 
				
				# Envia qual foi o botão inicial (ex: Fraco vai menos longe, Forte avança mais)
				payload_to_inject["button_strength"] = _active_strength
				
				return true
				
			"inactive":
				return false
				
			# CENÁRIO 2: Macro ativada (ex: Cancelou a preparação do chute num Dash!)
			_: 
				dynamic_target_state = "SystemState" 
				payload_to_inject["sub_state"] = status
				return true

	# =========================================================
	# FASE A: PROCURA A MEIA LUA NO BUFFER (O Início)
	# =========================================================
	var detected_btn = ""
	var detected_strength = ""
	
	# Prioridade 1: Chute Forte
	if buffer.is_sequence_buffered(sequence_heavy):
		buffer.consume_sequence()
		detected_btn = "kick_strong"
		detected_strength = "heavy"
		
	# Prioridade 2: Chute Fraco
	elif buffer.is_sequence_buffered(sequence_light):
		buffer.consume_sequence()
		detected_btn = "kick_light"
		detected_strength = "light"
		
	# SE O COMANDO FOI DETETADO, INICIA A PREPARAÇÃO DO CHUTE
	if detected_btn != "":
		
		# Lê a postura no momento exato do input
		var input_comp = buffer.input
		if input_comp and input_comp.get_movement_direction().y > 0.5:
			_forced_posture = "crouch"
		else:
			_forced_posture = "stand"
			
		# Guarda o contexto para a Fase B e avisa o Árbitro de Carga
		_active_charge_btn = detected_btn
		_active_strength = detected_strength
		_is_charging_motion = true
		mechanic.reset_charge()
		
		# Retorna false para a máquina de estados não transitar enquanto o botão não for solto!
		return false 
		
	return false
