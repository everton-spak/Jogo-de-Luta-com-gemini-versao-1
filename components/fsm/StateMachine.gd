class_name StateMachine
extends State

@export var initial_state_name: String
var current_state: State
var current_state_name: String = ""

var _global_state_map: Dictionary = {}

func _on_initialized() -> void:
	super._on_initialized()
	
	# Se eu for a Root (não tenho pai StateMachine)
	if not _is_child_of_fsm():
		_global_state_map.clear() # 🧹 CORREÇÃO 1: Esvazia o mapa antes de ler a árvore!
		_build_global_map(self)
	
	for child in sub_components.values(): 
		if child is State:
			child.fighter = self.fighter
			if child.has_method("_on_initialized"):
				child._on_initialized()
				
			var trans_callable = Callable(self, "_on_child_transition_requested")
			if not child.transition_requested.is_connected(trans_callable):
				child.transition_requested.connect(trans_callable)

# =========================================================
# FUNÇÕES VIRTUAIS (Evita o erro "Function not found")
# =========================================================
func _on_enter(_payload: Dictionary = {}) -> void:
	pass

func _on_exit() -> void:
	pass

func _on_physics_update(_delta: float) -> void:
	pass

# =========================================================
# FLUXO PRINCIPAL
# =========================================================
func enter(payload: Dictionary = {}) -> void:
	# 1. Dá a oportunidade ao roteador (HadoukenFSM, NormalAttack) de agir
	_on_enter(payload) 
	
	# 👇 A TRAVA DE SEGURANÇA CONTRA O LOOP INFINITO 👇
	# Se o _on_enter já ativou um filho com sucesso, abortamos!
	# Isto impede que a máquina tente ler o payload e crie um conflito duplo.
	if current_state != null:
		return
		
	# 2. Se o roteador não fez nada (ex: Attack.gd), usamos a busca automática
	var target_sub_state = payload.get("sub_state", initial_state_name)
	if target_sub_state != "":
		change_state(target_sub_state, payload)

func exit() -> void:
	_on_exit()
	if current_state:
		current_state.exit()
		current_state = null
	current_state_name = ""

func physics_update(delta: float) -> void:
	_on_physics_update(delta) 
	if current_state:
		current_state.physics_update(delta)

# --- SISTEMA DE BUSCA RECURSIVA ---
func _is_child_of_fsm() -> bool:
	var p = get_parent()
	while p != null:
		if p is StateMachine: return true
		p = p.get_parent()
	return false

func _build_global_map(root: StateMachine) -> void:
	for state_name in sub_components.keys():
		var state_node = sub_components[state_name]
		
		# 🧠 CORREÇÃO 2: Verificação Inteligente
		if root._global_state_map.has(state_name):
			# Se o nome já existe, verificamos se é um nó diferente a tentar roubar o nome.
			# Se for exatamente o mesmo nó, significa apenas que a FSM leu a árvore 2x (Seguro).
			if root._global_state_map[state_name] != state_node:
				push_error("⚠️ ERRO CRÍTICO: Tens dois nós diferentes a usar o mesmo nome: '" + state_name + "'. Muda o nome de um deles!")
		else:
			root._global_state_map[state_name] = state_node
		
		# Continua a busca para baixo se o filho for outra máquina de estados
		if state_node is StateMachine:
			state_node._build_global_map(root)

func find_state_recursive(target_name: String) -> State:
	if not _global_state_map.is_empty():
		return _global_state_map.get(target_name)
	var p = get_parent()
	while p != null:
		if p is StateMachine and not p._global_state_map.is_empty():
			return p._global_state_map.get(target_name)
		p = p.get_parent()
	return null

# --- SISTEMA DE TAGS ---
func get_tags() -> Array[String]:
	var tags: Array[String] = []
	tags.append_array(get_machine_tags())
	
	if current_state:
		tags.append_array(current_state.get_tags())
			
	var unique_tags: Array[String] = []
	for t in tags:
		if not t in unique_tags:
			unique_tags.append(t)
			
	return unique_tags

func get_machine_tags() -> Array[String]:
	return []

# --- TRANSIÇÕES ---
func change_state(new_state_name: String, payload: Dictionary = {}) -> void:
	if sub_components.has(new_state_name):
		if current_state: current_state.exit()
		current_state = sub_components[new_state_name] as State
		current_state_name = new_state_name 
		current_state.enter(payload)
	else:
		var target_node = find_state_recursive(new_state_name)
		if target_node: _resolve_hierarchical_transition(target_node, payload)

func _on_child_transition_requested(new_state_name: String, payload: Dictionary = {}) -> void:
	change_state(new_state_name, payload)

func _resolve_hierarchical_transition(target_node: State, payload: Dictionary) -> void:
	for child_name in sub_components.keys():
		var child = sub_components[child_name]
		
		if child == target_node or (child is StateMachine and child._contains_state_recursive(target_node)):
			# SEGURANÇA: Só injeta o sub_state se o alvo final NÃO FOR a própria FSM pai.
			if child != target_node:
				payload["sub_state"] = target_node.name
				
			change_state(child_name, payload)
			return
			
	transition_requested.emit(target_node.name, payload)

func _contains_state_recursive(target: State) -> bool:
	for child in sub_components.values():
		if child == target: return true
		if child is StateMachine and child._contains_state_recursive(target): return true
	return false
