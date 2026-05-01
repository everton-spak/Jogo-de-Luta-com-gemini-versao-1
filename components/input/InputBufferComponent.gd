class_name InputBuffer
extends Component

# --- CONFIGURAÇÕES DE TOLERÂNCIA (Ajustáveis no Inspector) ---
@export var buffer_window_msec: int = 250         # Janela máxima para completar uma meia-lua (Motion)
@export var charge_grace_msec: int = 250          # Tempo de tolerância após soltar a carga (Charge)
@export var simultaneous_tolerance_msec: int = 50 # Janela para considerar 2 botões como "simultâneos"

# Defina os botões de ataque do seu jogo. O buffer usa isso para saber o que ignorar 
# na hora de ler as setas para soltar golpes especiais.
const ACTION_BUTTONS = ["punch_heavy", "kick_heavy", "punch_light", "kick_light"]

# --- VARIÁVEIS INTERNAS ---
var _buffer: Array[Dictionary] = []
var _charge_time: Dictionary = {"B": 0.0, "D": 0.0}
var _charge_drop_time: Dictionary = {"B": 0, "D": 0}

# Referências a outros componentes
var input: Component
var facing_component: Component

func _on_initialized() -> void:
	# A nossa classe Component acha os outros sistemas automaticamente
	input = get_component("InputComponent")
	facing_component = get_component("FacingComponent")

func _process(delta: float) -> void:
	if not input: return
	
	_clean_old_inputs()
	_update_charge_timers(delta)
	
	# 1. Registando Botões de Ação
	for action in ACTION_BUTTONS:
		if input.is_action_just_pressed(action):
			_add_to_buffer(action)
			
	# 2. Registando Direcionais (Motion Inputs)
	var dir = input.get_movement_direction()
	var dir_string = _vector_to_direction_string(dir)
	
	# 👇 A MÁGICA DO JOGO DE LUTA: Transformar o vazio em "Neutro"
	if dir_string == "":
		dir_string = "N" 
	
	# Agora o buffer regista o Neutro. Se fizermos Frente -> Soltar -> Frente,
	# a lista ficará ["F", "N", "F"], permitindo que o duplo-toque funcione!
	if _buffer.is_empty() or _buffer.back()["input"] != dir_string:
		_add_to_buffer(dir_string)
		
		# 👇 LIGA O RAIO-X AQUI 👇
		#var lista_de_inputs = []
		#for item in _buffer:
		#	lista_de_inputs.append(item["input"])
		#print("BUFFER: ", lista_de_inputs)
		
# --- FUNÇÕES BÁSICAS DO BUFFER ---

func _add_to_buffer(input_name: String) -> void:
	_buffer.append({
		"input": input_name,
		"timestamp": Time.get_ticks_msec()
	})

func _clean_old_inputs() -> void:
	var current_time = Time.get_ticks_msec()
	_buffer = _buffer.filter(func(item): return current_time - item["timestamp"] <= buffer_window_msec)

# Converte o Vector2 para notação de jogo de luta, invertendo Esquerda/Direita 
# baseado na posição do inimigo.
func _vector_to_direction_string(v: Vector2) -> String:
	if v == Vector2.ZERO: return ""
	
	var facing = 1.0
	if facing_component:
		facing = facing_component.current_facing
		
	var forward = v.x * facing # A mágica da inversão acontece aqui
	
	if v.y > 0.5 and forward > 0.5: return "DF"  # Down-Forward
	if v.y > 0.5 and forward < -0.5: return "DB" # Down-Back
	if v.y < -0.5 and forward > 0.5: return "UF" # Up-Forward
	if v.y < -0.5 and forward < -0.5: return "UB" # Up-Back
	
	if v.y > 0.5: return "D"  # Down
	if v.y < -0.5: return "U" # Up
	
	if forward > 0.5: return "F"  # Forward Dinâmico
	if forward < -0.5: return "B" # Back Dinâmico
	
	return ""

# --- LEITURA DE GOLPES SIMPLES E MOTION (Hadouken) ---

func is_action_buffered(action_name: String) -> bool:
	for item in _buffer:
		if item["input"] == action_name:
			return true
	return false

func consume_action(action_name: String) -> void:
	for i in range(_buffer.size() - 1, -1, -1):
		if _buffer[i]["input"] == action_name:
			_buffer.remove_at(i)
			break

func is_sequence_buffered(sequence: Array) -> bool:
	if _buffer.size() < sequence.size(): return false
	
	var seq_index = sequence.size() - 1
	for i in range(_buffer.size() - 1, -1, -1):
		if _buffer[i]["input"] == sequence[seq_index]:
			seq_index -= 1
			if seq_index < 0:
				return true
	return false

func consume_sequence() -> void:
	_buffer.clear() # Limpa tudo para evitar golpes em duplicidade

# --- LEITURA DE BOTÕES SIMULTÂNEOS E EX MOVES ---

func is_simultaneous_buffered(actions: Array) -> bool:
	var found_timestamps: Array[int] = []
	
	for action in actions:
		var found: bool = false
		for i in range(_buffer.size() - 1, -1, -1):
			if _buffer[i]["input"] == action:
				found_timestamps.append(_buffer[i]["timestamp"])
				found = true
				break
		if not found: return false
			
	var max_time = found_timestamps.max()
	var min_time = found_timestamps.min()
	return (max_time - min_time) <= simultaneous_tolerance_msec

func consume_simultaneous(actions: Array) -> void:
	for action in actions:
		consume_action(action)

# Lê movimentos ignorando os botões de ataque no meio do caminho.
# Perfeito para Super Hadouken ou EX Hadouken.
func is_motion_with_buttons(motion: Array, buttons: Array) -> bool:
	if not is_simultaneous_buffered(buttons):
		return false
		
	var motion_index = motion.size() - 1
	for i in range(_buffer.size() - 1, -1, -1):
		var input_name = _buffer[i]["input"]
		
		# Ignora botões de ataque amassados acidentalmente
		if input_name in ACTION_BUTTONS:
			continue
			
		if input_name == motion[motion_index]:
			motion_index -= 1
			if motion_index < 0:
				return true
	return false

# --- SISTEMA DE GOLPES CARREGADOS (Sonic Boom) ---

func _update_charge_timers(delta: float) -> void:
	var dir = input.get_movement_direction()
	var dir_string = _vector_to_direction_string(dir)
	var current_time = Time.get_ticks_msec()
	
	# Atualiza carga de TRÁS ("B"). "DB" (Diagonal Defesa) também carrega!
	if "B" in dir_string:
		_charge_time["B"] += delta * 1000.0
		_charge_drop_time["B"] = current_time
	else:
		if current_time - _charge_drop_time["B"] > charge_grace_msec:
			_charge_time["B"] = 0.0

	# Atualiza carga de BAIXO ("D"). "DB" e "DF" também carregam!
	if "D" in dir_string:
		_charge_time["D"] += delta * 1000.0
		_charge_drop_time["D"] = current_time
	else:
		if current_time - _charge_drop_time["D"] > charge_grace_msec:
			_charge_time["D"] = 0.0

func is_charge_ready(charge_dir: String, required_charge_msec: float) -> bool:
	return _charge_time.get(charge_dir, 0.0) >= required_charge_msec

func consume_charge(charge_dir: String) -> void:
	_charge_time[charge_dir] = 0.0

# =========================================================
# O NOVO MOTOR DE LEITURA (Orientado a Componentes)
# =========================================================
func check_special_moves(_provided_tags: Array = []) -> Dictionary:
	# 1. BUSCA AS TAGS GLOBAIS DA FSM: Ignoramos as tags fornecidas localmente pelo estado
	# Porque os estados folha (ex: IdleState) não conhecem as tags dos seus parentes (ex: Grounded).
	var current_state_tags: Array = _provided_tags
	var fsm = get_component("StateMachine")
	if fsm:
		current_state_tags = fsm.get_tags()

	# 2. SAÍDA DE EMERGÊNCIA: Se as tags forem nulas ou não forem uma lista, ignora!
	if current_state_tags == null or typeof(current_state_tags) != TYPE_ARRAY:
		return {} # Retorna um dicionário vazio para o boneco continuar a mover-se
	
	for child in get_children():
		if child is MoveComponent: 
			
			var is_allowed = false
			
			# --- AQUI ESTÁ A GRANDE ALTERAÇÃO ---
			# Se as allowed_tags do golpe estiverem VAZIAS no Inspector, ele é sempre aceite!
			if child.allowed_tags.is_empty():
				is_allowed = true
			else:
				# Caso contrário, tem de bater certo com as tags atuais do personagem
				for tag in current_state_tags:
					if tag in child.allowed_tags:
						is_allowed = true
						break
			
			if is_allowed:
				if child.check_execution(self):
					
					var final_state = child.target_state_name
					var final_payload = {}
					if "dynamic_target_state" in child and child.dynamic_target_state != "":
						final_state = child.dynamic_target_state
					if "payload_to_inject" in child and typeof(child.payload_to_inject) == TYPE_DICTIONARY and not child.payload_to_inject.is_empty():
						final_payload = child.payload_to_inject.duplicate()
					else:
						if "sub_state" in child and child.sub_state != "":
							final_payload["sub_state"] = child.sub_state
						if "forced_posture" in child and child.forced_posture != "":
							final_payload["forced_posture"] = child.forced_posture
					
					return {
						"state": final_state,
						"payload": final_payload
					}
	
	return {}
