class_name State
extends Component

signal transition_requested(new_state_name: String, payload: Dictionary)
var input_buffer: Component
@export var cancel_routes: Array[String] = []
@export var can_cancel_self: bool = false


var anim: Component
var facing: Component
var hitbox: Component
var hurtbox: Component
var proximity: Component
var input: Component
var movement: Component
var health: Component
var vfx: Component
var combo_scaling : Component

func _on_initialized() -> void:
	if not fighter:
		var current_node = get_parent()
		while current_node != null:
			if current_node is CharacterBody2D:
				fighter = current_node
				break
			current_node = current_node.get_parent()
			
	if not fighter:
		push_error("ERRO GRAVE: O Estado " + name + " não conseguiu achar o Fighter na árvore!")
		return

	var found_anim = get_component("AnimatedSpriteComponent")
	if found_anim is AnimatedSpriteComponent: anim = found_anim
	input_buffer = get_component("InputBufferComponent")
	facing = get_component("FacingComponent")
	hitbox = get_component("HitboxComponent")
	hurtbox = get_component("HurtBoxComponent")
	proximity = get_component("ProximityBoxComponent")
	input = get_component("InputComponent")
	movement = get_component("MovementComponent")
	health = get_component("HealthComponent")
	vfx = get_component("VfxComponent")
	combo_scaling = get_component("ScalingComboComponent")

func enter(_payload: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

# Retorna tags de um estado final (folha)
func get_tags() -> Array[String]:
	return []
	
	
## =========================================================
# ⚡ MOTOR UNIVERSAL DE CANCELAMENTOS
# =========================================================

func process_cancel_routes() -> bool:
	if cancel_routes.is_empty() or input_buffer == null:
		return false

	var command = input_buffer.check_special_moves(get_tags())
	
	if command.has("state"):
		var requested_state = command["state"]
		var payload = command.get("payload", {})
		
		# 1. Descobrir o nome verdadeiro do golpe (Neto)
		var actual_move_name = requested_state
		if payload.has("sub_state") and typeof(payload["sub_state"]) == TYPE_STRING and payload["sub_state"] != "":
			actual_move_name = payload["sub_state"]
			
		# 👇 A NOVA TRAVA ANTI-SPAM 👇
		# Se o jogador pedir o exato mesmo golpe em que já estamos, rejeita!
		if actual_move_name == self.name and not can_cancel_self:
			print("🛑 Bloqueado: Não podes cancelar um golpe nele mesmo!")
			return false

		# 2. Checagem Direta (Ex: "LightPunch" direto na lista)
		if actual_move_name in cancel_routes:
			transition_requested.emit(requested_state, payload)
			return true
			
		# 3. Checagem Hierárquica / "Por Pasta"
		var root_fsm = get_component("StateMachine")
		if root_fsm and root_fsm is StateMachine:
			var target_node = root_fsm.find_state_recursive(actual_move_name)
			
			if target_node:
				print("\n🔍 [Categorical Cancel] Procurando pastas acima de: ", target_node.name)
				var current_parent = target_node.get_parent()
				
				# 👇 CORREÇÃO: Agora sobe a árvore toda, não importa se é StateMachine ou Node normal!
				# Vai parar apenas quando chegar ao limite do Lutador.
				while current_parent != null and current_parent != fighter:
					print("📂 Lendo a pasta: '", current_parent.name, "'")
					
					if current_parent.name in cancel_routes:
						print("🟢 SUCESSO! A pasta '", current_parent.name, "' autorizou o combo!")
						transition_requested.emit(requested_state, payload)
						return true
						
					current_parent = current_parent.get_parent()
					
				print("🔴 FALHA: Nenhuma das pastas acima está na Lista VIP: ", cancel_routes, "\n")

	return false
