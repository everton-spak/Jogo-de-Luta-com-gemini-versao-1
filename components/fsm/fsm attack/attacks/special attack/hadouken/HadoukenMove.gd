class_name HadoukenMove
extends MoveComponent

# =========================================================
# 1. CONFIGURAÇÃO DOS COMANDOS (Ajuste no Inspector)
# =========================================================
@export var sequence_heavy: Array[String] = ["D", "DF", "F", "punch_heavy"]
@export var sequence_light: Array[String] = ["D", "DF", "F", "punch_light"]
@export var sequence_light_crouch: Array[String] = ["D", "DB", "B" ,"punch_light"]
@export var sub_state: String = "Hadouken"

# Variáveis que a FSM (Máquina de Estados) vai ler
var dynamic_target_state: String = ""
var payload_to_inject: Dictionary = {}

# Variáveis internas para controlar a Carga
var _is_charging_motion: bool = false 
var _active_strength: String = ""   
var _active_button_name: String = ""

# =========================================================
# 2. EXECUÇÃO PRINCIPAL
# =========================================================
func check_execution(buffer: InputBuffer) -> bool:
	
	# --- FASE B: GESTÃO DA CARGA (Se o jogador já fez a meia-lua) ---
	if _is_charging_motion:
		# Verificamos se o jogador SOLTOU o botão
		# Usamos o player_prefix (ex: "p1_") para saber qual controle ler
		var btn_path = buffer.input.player_prefix + _active_button_name
		
		if not Input.is_action_pressed(btn_path):
			# O JOGADOR SOLTOU O BOTÃO! 
			_is_charging_motion = false
			_prepare_payload("normal", 1.0, _active_strength)
			
			print("💥 HADOUKEN LANÇADO! Força: ", _active_strength)
			return true # Retorna TRUE para o boneco mudar para o estado de ataque
			
		return false # Ainda segurando o botão... não mude de estado ainda.

	# --- FASE A: DETECÇÃO DO COMANDO (A Meia-Lua) ---
	
	# 3. Tenta crouchHadouken Leve
	if not sequence_light.is_empty() and buffer.is_sequence_buffered(sequence_light_crouch):
		buffer.consume_sequence()
		_is_charging_motion = true
		_active_strength = "light"
		_active_button_name = "punch_light"
		print("💨 MEIA-LUA CROUCH DETECTADA (Leve): Carregando...")
		return false
	
	# 1. Tenta Hadouken Pesado
	if not sequence_heavy.is_empty() and buffer.is_sequence_buffered(sequence_heavy):
		buffer.consume_sequence()
		_is_charging_motion = true
		_active_strength = "heavy"
		_active_button_name = "punch_heavy"
		print("💨 MEIA-LUA DETECTADA (Pesado): Carregando...")
		return false # Retorna FALSE para não pular o estado de carga

	# 2. Tenta Hadouken Leve
	if not sequence_light.is_empty() and buffer.is_sequence_buffered(sequence_light):
		buffer.consume_sequence()
		_is_charging_motion = true
		_active_strength = "light"
		_active_button_name = "punch_light"
		print("💨 MEIA-LUA DETECTADA (Leve): Carregando...")
		return false
		
	

	# Se não detectou nada, retorna falso por segurança
	return false

# =========================================================
# 3. AUXILIARES
# =========================================================
func _prepare_payload(level: String, multiplier: float, strength: String) -> void:
	payload_to_inject.clear()
	
	# Define para qual estado o boneco vai (Ex: SpecialAttack)
	dynamic_target_state = target_state_name 
	
	# Dados que o estado de ataque vai usar para saber o que fazer
	payload_to_inject["sub_state"] = sub_state
	payload_to_inject["charge_level"] = level
	payload_to_inject["multiplier"] = multiplier
	payload_to_inject["strength"] = strength
