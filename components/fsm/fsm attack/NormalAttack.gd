class_name NormalAttack
extends StateMachine

var _category_tags: Array[String] = ["Normal"]

func _on_enter(payload: Dictionary = {}) -> void:
	# 1. Chama o Avô (Attack.gd) para tratar a física
	super._on_enter(payload)
	
	if fighter.is_on_floor():
		fighter.velocity.x = 0
	
	# 2. ROTEAMENTO INTELIGENTE (A TUA IDEIA!)
	var move_name = payload.get("sub_state", "") 
	var posture = payload.get("forced_posture", "stand").capitalize() 
	
	var target_node_specific = posture + move_name
	
	# 🧠 Em vez de verificar apenas os filhos diretos (sub_components),
	# usamos a inteligência da FSM para procurar na árvore inteira!
	if target_node_specific != "" and find_state_recursive(target_node_specific) != null:
		change_state(target_node_specific, payload)
		
	elif move_name != "" and find_state_recursive(move_name) != null:
		change_state(move_name, payload)
		
	else:
		push_warning("Ataque normal não encontrado na FSM: " + target_node_specific)
		transition_requested.emit("IdleState", {})

func get_machine_tags() -> Array[String]:
	return _category_tags
